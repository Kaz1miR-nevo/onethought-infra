# =============================================================================
# OneThought Infrastructure - ECR Configuration
# =============================================================================
# This file contains additional ECR-related resources and lifecycle policies.
# =============================================================================

# =============================================================================
# ECR Pull Through Cache (Optional)
# =============================================================================
# Enables caching of public container images to reduce pull times
# and provide resilience against upstream availability issues.

resource "aws_ecr_pull_through_cache_rule" "docker_hub" {
  ecr_repository_prefix = "docker-hub"
  upstream_registry_url = "registry-1.docker.io"
}

resource "aws_ecr_pull_through_cache_rule" "quay" {
  ecr_repository_prefix = "quay"
  upstream_registry_url = "quay.io"
}

# =============================================================================
# ECR Replication (Cross-Region DR)
# =============================================================================
# Uncomment for production to enable cross-region replication

# resource "aws_ecr_replication_configuration" "replication" {
#   count = var.environment == "prod" ? 1 : 0
#   
#   replication_configuration {
#     rule {
#       destination {
#         region      = "us-east-1"
#         registry_id = data.aws_caller_identity.current.account_id
#       }
#     }
#   }
# }

# =============================================================================
# ECR Registry Scanning Configuration
# =============================================================================

resource "aws_ecr_registry_scanning_configuration" "scanning" {
  scan_type = "ENHANCED"
  
  rule {
    scan_frequency = "CONTINUOUS_SCAN"
    
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

