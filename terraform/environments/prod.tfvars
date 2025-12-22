# =============================================================================
# Production Environment Configuration
# =============================================================================
# This file contains environment-specific values for the production environment.
# Usage: terraform apply -var-file=environments/prod.tfvars
# 
# ⚠️ WARNING: Be extremely careful when applying changes to production!
# Always test on stage first and review the plan carefully.
# =============================================================================

# General
environment  = "prod"
project_name = "onethought"
aws_region   = "eu-central-1"

# Network
vpc_cidr = "10.1.0.0/16"  # Different CIDR from stage

# EKS
kubernetes_version = "1.28"

node_groups = {
  general = {
    instance_types = ["t3.large", "t3.xlarge"]
    min_size       = 3
    max_size       = 10
    desired_size   = 3
    disk_size      = 100
    labels = {
      environment = "prod"
      role        = "general"
    }
    taints = []
  }
  
  # Dedicated nodes for high-memory workloads (optional)
  # memory-optimized = {
  #   instance_types = ["r6i.large", "r6i.xlarge"]
  #   min_size       = 0
  #   max_size       = 5
  #   desired_size   = 0
  #   disk_size      = 100
  #   labels = {
  #     environment = "prod"
  #     role        = "memory-optimized"
  #   }
  #   taints = [{
  #     key    = "workload"
  #     value  = "memory-intensive"
  #     effect = "NO_SCHEDULE"
  #   }]
  # }
}

# Logging
log_retention_days = 90

# GitHub
github_org  = "your-org"
github_repo = "onethought"

# Domain
domain_name    = "birka.one"
hosted_zone_id = ""  # Set this to your Route53 hosted zone ID

# WAF - More restrictive in production
waf_rate_limit = 1000

# Cost Optimization - No spot instances in production for stability
enable_spot_instances = false

# Monitoring
enable_monitoring = true

