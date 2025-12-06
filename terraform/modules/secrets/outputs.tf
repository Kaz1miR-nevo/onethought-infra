# =============================================================================
# Secrets Manager Module - Outputs
# =============================================================================

output "secret_arn" {
  description = "ARN of the secrets manager secret"
  value       = aws_secretsmanager_secret.main.arn
}

output "secret_name" {
  description = "Name of the secrets manager secret"
  value       = aws_secretsmanager_secret.main.name
}

output "policy_arn" {
  description = "ARN of the IAM policy for secrets access"
  value       = aws_iam_policy.secrets_access.arn
}

