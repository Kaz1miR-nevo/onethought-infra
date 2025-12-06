# =============================================================================
# ALB Controller Module - Outputs
# =============================================================================

output "role_arn" {
  description = "ARN of the ALB Controller IAM role"
  value       = aws_iam_role.alb_controller.arn
}

