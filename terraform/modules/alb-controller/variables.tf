# =============================================================================
# ALB Controller Module - Variables
# =============================================================================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

