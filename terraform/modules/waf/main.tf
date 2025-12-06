# =============================================================================
# WAF Module - Web Application Firewall
# =============================================================================

resource "aws_wafv2_web_acl" "main" {
  name        = "${var.name_prefix}-waf"
  description = "WAF for ${var.name_prefix}"
  scope       = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  # Rate limiting rule
  rule {
    name     = "rate-limit"
    priority = 1
    
    override_action {
      none {}
    }
    
    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name_prefix}-rate-limit"
      sampled_requests_enabled   = true
    }
  }
  
  # AWS Managed Common Rule Set
  dynamic "rule" {
    for_each = var.enable_aws_managed_rules ? [1] : []
    content {
      name     = "aws-common-rules"
      priority = 2
      
      override_action {
        none {}
      }
      
      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-common-rules"
        sampled_requests_enabled   = true
      }
    }
  }
  
  # AWS Managed Known Bad Inputs
  dynamic "rule" {
    for_each = var.enable_aws_managed_rules ? [1] : []
    content {
      name     = "aws-bad-inputs"
      priority = 3
      
      override_action {
        none {}
      }
      
      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesKnownBadInputsRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-bad-inputs"
        sampled_requests_enabled   = true
      }
    }
  }
  
  # SQL Injection Protection
  dynamic "rule" {
    for_each = var.enable_aws_managed_rules ? [1] : []
    content {
      name     = "aws-sql-injection"
      priority = 4
      
      override_action {
        none {}
      }
      
      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesSQLiRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-sql-injection"
        sampled_requests_enabled   = true
      }
    }
  }
  
  # Bot Control (optional, has additional cost)
  dynamic "rule" {
    for_each = var.enable_bot_control ? [1] : []
    content {
      name     = "aws-bot-control"
      priority = 5
      
      override_action {
        none {}
      }
      
      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }
      
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name_prefix}-bot-control"
        sampled_requests_enabled   = true
      }
    }
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name_prefix}-waf"
    sampled_requests_enabled   = true
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-waf"
  })
}

# CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf" {
  name              = "aws-waf-logs-${var.name_prefix}"
  retention_in_days = 30
  
  tags = var.tags
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]
  resource_arn            = aws_wafv2_web_acl.main.arn
  
  logging_filter {
    default_behavior = "KEEP"
    
    filter {
      behavior = "DROP"
      
      condition {
        action_condition {
          action = "ALLOW"
        }
      }
      
      requirement = "MEETS_ALL"
    }
  }
}

