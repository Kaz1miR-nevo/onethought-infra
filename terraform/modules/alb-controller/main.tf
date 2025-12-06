# =============================================================================
# ALB Controller Module
# =============================================================================
# Installs AWS Load Balancer Controller for Ingress management
# =============================================================================

# IAM Role for ALB Controller
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.cluster_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })
  
  tags = var.tags
}

# IAM Policy for ALB Controller
resource "aws_iam_role_policy" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"
  role = aws_iam_role.alb_controller.id
  
  policy = file("${path.module}/iam-policy.json")
}

# Helm Release for ALB Controller
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller.arn
  }
  
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  
  set {
    name  = "region"
    value = data.aws_region.current.name
  }
}

data "aws_region" "current" {}

