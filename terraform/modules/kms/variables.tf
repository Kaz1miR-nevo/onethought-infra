# =============================================================================
# KMS Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "key_administrators" {
  description = "List of IAM ARNs that can administer the key"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

