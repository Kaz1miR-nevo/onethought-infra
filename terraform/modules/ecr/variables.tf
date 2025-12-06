# =============================================================================
# ECR Module - Variables
# =============================================================================

variable "name_prefix" {
  description = "Prefix for repository names"
  type        = string
}

variable "repositories" {
  description = "List of repository names to create"
  type        = list(string)
}

variable "image_retention_count" {
  description = "Number of images to retain"
  type        = number
  default     = 30
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

