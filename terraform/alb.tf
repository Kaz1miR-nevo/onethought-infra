# =============================================================================
# OneThought Infrastructure - ALB Configuration
# =============================================================================
# This file contains additional ALB-related resources including
# target groups, listener rules, and WAF associations.
# =============================================================================

# =============================================================================
# SSL Certificate
# =============================================================================

# Request SSL certificate from ACM
resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-certificate"
  })
}

# Certificate validation with Route53 (if hosted zone is configured)
resource "aws_route53_record" "cert_validation" {
  for_each = var.hosted_zone_id != "" ? {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}
  
  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
  
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "main" {
  count = var.hosted_zone_id != "" ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# =============================================================================
# Route53 DNS Records
# =============================================================================

# Main domain record (created by Ingress controller, but placeholder here)
# The actual record will be managed by external-dns or ALB Ingress Controller

resource "aws_route53_record" "main" {
  count = var.hosted_zone_id != "" ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = var.environment == "prod" ? var.domain_name : "${var.environment}.${var.domain_name}"
  type    = "A"
  
  alias {
    name                   = "dualstack.placeholder.elb.amazonaws.com"  # Updated by Ingress
    zone_id                = "Z32O12XQLNTSW2"  # eu-central-1 ELB hosted zone
    evaluate_target_health = true
  }
  
  lifecycle {
    ignore_changes = [alias]  # Managed by ALB Ingress Controller
  }
}

# =============================================================================
# WAF Association with ALB
# =============================================================================
# Note: WAF WebACL is created in the WAF module, association is here

# The actual association happens when the ALB is created by the Ingress controller
# This is a placeholder that documents the expected configuration

# resource "aws_wafv2_web_acl_association" "alb" {
#   count = var.environment == "prod" ? 1 : 0
#   
#   resource_arn = "arn:aws:elasticloadbalancing:${var.aws_region}:${data.aws_caller_identity.current.account_id}:loadbalancer/app/..."
#   web_acl_arn  = module.waf[0].web_acl_arn
# }

# =============================================================================
# Security Group for ALB
# =============================================================================

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = module.vpc.vpc_id
  
  # Allow HTTP from anywhere (redirects to HTTPS)
  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  # Allow HTTPS from anywhere
  ingress {
    description      = "HTTPS from anywhere"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  # Allow all outbound traffic
  egress {
    description      = "All outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb-sg"
  })
}

# Security group rule to allow traffic from ALB to EKS nodes
resource "aws_security_group_rule" "alb_to_nodes" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = module.eks.node_security_group_id
  description              = "Allow traffic from ALB to EKS nodes"
}

