# =============================================================================
# OneThought Infrastructure - Outputs
# =============================================================================
# These outputs provide important information about the created resources.
# They can be used by CI/CD pipelines and other automation tools.
# =============================================================================

# =============================================================================
# EKS Cluster Outputs
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster"
  value       = module.eks.oidc_issuer_url
}

# =============================================================================
# VPC Outputs
# =============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

# =============================================================================
# ECR Outputs
# =============================================================================

output "ecr_repository_urls" {
  description = "URLs of ECR repositories"
  value       = module.ecr.repository_urls
}

output "ecr_frontend_url" {
  description = "ECR repository URL for frontend"
  value       = module.ecr.repository_urls["frontend"]
}

output "ecr_backend_url" {
  description = "ECR repository URL for backend"
  value       = module.ecr.repository_urls["backend"]
}

# =============================================================================
# Security Outputs
# =============================================================================

output "kms_key_id" {
  description = "ID of the KMS key for encryption"
  value       = module.kms.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for encryption"
  value       = module.kms.key_arn
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = module.secrets.secret_arn
}

# =============================================================================
# GitHub Actions Outputs
# =============================================================================

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

# =============================================================================
# ALB Controller Outputs
# =============================================================================

output "alb_controller_role_arn" {
  description = "ARN of the IAM role for ALB Controller"
  value       = module.alb_controller.role_arn
}

# =============================================================================
# Monitoring Outputs
# =============================================================================

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}

# =============================================================================
# Configuration Commands
# =============================================================================

output "configure_kubectl" {
  description = "Command to configure kubectl for the cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "deploy_command" {
  description = "Command to deploy the application"
  value       = "helm upgrade --install onethought ../helm/onethought -f ../helm/onethought/values.${var.environment}.yaml"
}

# =============================================================================
# Environment Information
# =============================================================================

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "account_id" {
  description = "AWS account ID"
  value       = data.aws_caller_identity.current.account_id
}

