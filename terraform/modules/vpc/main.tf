# =============================================================================
# VPC Module - Network Infrastructure
# =============================================================================
# Creates a production-ready VPC with public and private subnets,
# NAT gateways, and proper tagging for EKS integration.
# =============================================================================

# =============================================================================
# VPC
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# =============================================================================
# Internet Gateway
# =============================================================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

# =============================================================================
# NAT Gateways
# =============================================================================

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.azs)
  domain = "vpc"
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per AZ for high availability)
resource "aws_nat_gateway" "main" {
  count         = length(var.azs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# =============================================================================
# Public Subnets
# =============================================================================

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-public-${var.azs[count.index]}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
    Tier                                        = "public"
  })
}

# =============================================================================
# Private Subnets
# =============================================================================

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  
  tags = merge(var.tags, {
    Name                                        = "${var.name_prefix}-private-${var.azs[count.index]}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
    Tier                                        = "private"
  })
}

# =============================================================================
# Route Tables
# =============================================================================

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

# Private route tables (one per AZ)
resource "aws_route_table" "private" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })
}

# =============================================================================
# Route Table Associations
# =============================================================================

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# =============================================================================
# Flow Logs
# =============================================================================

resource "aws_flow_log" "main" {
  count                = var.environment == "prod" ? 1 : 0
  iam_role_arn         = aws_iam_role.flow_log[0].arn
  log_destination      = aws_cloudwatch_log_group.flow_log[0].arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
  max_aggregation_interval = 60
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-flow-log"
  })
}

resource "aws_cloudwatch_log_group" "flow_log" {
  count             = var.environment == "prod" ? 1 : 0
  name              = "/aws/vpc/${var.name_prefix}/flow-logs"
  retention_in_days = 30
  
  tags = var.tags
}

resource "aws_iam_role" "flow_log" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.name_prefix}-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = var.tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.name_prefix}-flow-log-policy"
  role  = aws_iam_role.flow_log[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

