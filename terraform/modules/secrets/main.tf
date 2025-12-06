# =============================================================================
# Secrets Manager Module
# =============================================================================

resource "aws_secretsmanager_secret" "main" {
  name        = "${var.name_prefix}/app-secrets"
  description = "Application secrets for ${var.name_prefix}"
  kms_key_id  = var.kms_key_id
  
  recovery_window_in_days = var.environment == "prod" ? 30 : 7
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-app-secrets"
  })
}

# Initial secret version with placeholder values
# These should be updated manually after creation
resource "aws_secretsmanager_secret_version" "main" {
  secret_id = aws_secretsmanager_secret.main.id
  
  secret_string = jsonencode({
    # Database
    SUPABASE_URL          = "placeholder"
    SUPABASE_ANON_KEY     = "placeholder"
    SUPABASE_SERVICE_KEY  = "placeholder"
    
    # Authentication
    JWT_SECRET            = "placeholder"
    
    # External APIs
    TRANSLATION_API_KEY   = "placeholder"
    
    # Add other secrets as needed
  })
  
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# IAM Policy for accessing secrets
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.name_prefix}-secrets-access"
  description = "Policy to access application secrets"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_id
      }
    ]
  })
  
  tags = var.tags
}

