# =============================================================================
# OneThought Infrastructure - Variables
# =============================================================================
# This file defines all configurable variables for the infrastructure.
# Default values are provided where sensible, with environment-specific
# overrides in the environments/*.tfvars files.
# =============================================================================

# =============================================================================
# General Settings
# =============================================================================

variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
  default     = "onethought"
}

variable "environment" {
  description = "Environment name (stage, prod)"
  type        = string
  
  validation {
    condition     = contains(["stage", "prod"], var.environment)
    error_message = "Environment must be 'stage' or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

# =============================================================================
# Network Settings
# =============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# =============================================================================
# EKS Settings
# =============================================================================

variable "kubernetes_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Configuration for EKS node groups"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  
  default = {
    general = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      disk_size      = 50
      labels         = {}
      taints         = []
    }
  }
}

# =============================================================================
# Security Settings
# =============================================================================

variable "key_administrators" {
  description = "List of IAM ARNs that can administer KMS keys"
  type        = list(string)
  default     = []
}

variable "waf_rate_limit" {
  description = "Rate limit for WAF (requests per 5 minutes)"
  type        = number
  default     = 2000
}

# =============================================================================
# Logging Settings
# =============================================================================

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

# =============================================================================
# GitHub Integration
# =============================================================================

variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "your-org"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "onethought"
}

# =============================================================================
# Domain Settings
# =============================================================================

variable "domain_name" {
  description = "Primary domain name for the application"
  type        = string
  default     = "birka.one"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID (if using Route53)"
  type        = string
  default     = ""
}

# =============================================================================
# Application Settings
# =============================================================================

variable "frontend_port" {
  description = "Port for frontend service"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port for backend service"
  type        = number
  default     = 3001
}

# =============================================================================
# Monitoring Settings
# =============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring stack (Grafana, Loki, Prometheus)"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (should be stored in secrets)"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# Cost Optimization
# =============================================================================

variable "enable_spot_instances" {
  description = "Use spot instances for non-production workloads"
  type        = bool
  default     = false
}

variable "spot_instance_pools" {
  description = "Number of spot instance pools for node groups"
  type        = number
  default     = 2
}

