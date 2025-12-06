# =============================================================================
# Stage Environment Configuration
# =============================================================================
# This file contains environment-specific values for the stage environment.
# Usage: terraform apply -var-file=environments/stage.tfvars
# =============================================================================

# General
environment  = "stage"
project_name = "onethought"
aws_region   = "eu-central-1"

# Network
vpc_cidr = "10.0.0.0/16"

# EKS
kubernetes_version = "1.28"

node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    disk_size      = 50
    labels = {
      environment = "stage"
      role        = "general"
    }
    taints = []
  }
}

# Logging
log_retention_days = 14

# GitHub
github_org  = "your-org"
github_repo = "onethought"

# Domain
domain_name    = "onethought.app"
hosted_zone_id = ""  # Set this if using Route53

# WAF
waf_rate_limit = 2000

# Cost Optimization
enable_spot_instances = true
spot_instance_pools   = 2

# Monitoring
enable_monitoring = true

