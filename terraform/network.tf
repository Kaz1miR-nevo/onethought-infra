# =============================================================================
# OneThought Infrastructure - Network Module Configuration
# =============================================================================
# This file contains network-related resources that are managed directly
# in the root module rather than in the VPC module.
# =============================================================================

# =============================================================================
# VPC Endpoints for Private Access
# =============================================================================
# These endpoints allow private access to AWS services without going
# through the internet, improving security and reducing data transfer costs.

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  
  route_table_ids = module.vpc.private_route_table_ids
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

# ECR API Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-api-endpoint"
  })
}

# ECR DKR Endpoint (for Docker registry)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ecr-dkr-endpoint"
  })
}

# CloudWatch Logs Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-logs-endpoint"
  })
}

# STS Endpoint (for IAM role assumption)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sts-endpoint"
  })
}

# Secrets Manager Endpoint
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-secretsmanager-endpoint"
  })
}

# =============================================================================
# Security Group for VPC Endpoints
# =============================================================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc-endpoints-sg"
  })
}

# =============================================================================
# Network ACLs for Additional Security
# =============================================================================

# Private subnet NACL
resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Allow all internal traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }
  
  # Allow ephemeral ports from internet (for NAT responses)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Allow all outbound traffic
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-nacl"
  })
}

# Public subnet NACL
resource "aws_network_acl" "public" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  # Allow HTTP
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  
  # Allow HTTPS
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  # Allow ephemeral ports (for responses)
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  
  # Allow all internal traffic
  ingress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }
  
  # Allow all outbound traffic
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-nacl"
  })
}

