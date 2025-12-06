# =============================================================================
# WAF Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "rate_limit" {
  description = "Rate limit (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_aws_managed_rules" {
  description = "Enable AWS managed rule sets"
  type        = bool
  default     = true
}

variable "enable_bot_control" {
  description = "Enable bot control (additional cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}

