# =============================================================================
# EKS Module - Outputs
# =============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "node_role_arn" {
  description = "ARN of the node IAM role"
  value       = aws_iam_role.node.arn
}

output "cluster_role_arn" {
  description = "ARN of the cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

