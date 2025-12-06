# =============================================================================
# OneThought Infrastructure - EKS Additional Configuration
# =============================================================================
# This file contains additional EKS-related resources that supplement
# the EKS module, including addons and Kubernetes resources.
# =============================================================================

# =============================================================================
# EKS Addons
# =============================================================================

# VPC CNI Addon - manages pod networking
resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "vpc-cni"
  addon_version            = "v1.15.4-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni.arn
  
  depends_on = [module.eks]
}

# CoreDNS Addon - provides DNS for the cluster
resource "aws_eks_addon" "coredns" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  addon_version     = "v1.10.1-eksbuild.6"
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [module.eks]
}

# Kube-proxy Addon - network proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  addon_version     = "v1.28.4-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
  
  depends_on = [module.eks]
}

# EBS CSI Driver Addon - for persistent volumes
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.25.0-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  
  depends_on = [module.eks]
}

# =============================================================================
# IAM Role for VPC CNI
# =============================================================================

resource "aws_iam_role" "vpc_cni" {
  name = "${local.name_prefix}-vpc-cni-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

# =============================================================================
# IAM Role for EBS CSI Driver
# =============================================================================

resource "aws_iam_role" "ebs_csi" {
  name = "${local.name_prefix}-ebs-csi-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

# =============================================================================
# Kubernetes Namespaces
# =============================================================================

resource "kubernetes_namespace" "application" {
  metadata {
    name = "onethought"
    
    labels = {
      name        = "onethought"
      environment = var.environment
    }
  }
  
  depends_on = [module.eks]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    
    labels = {
      name = "monitoring"
    }
  }
  
  depends_on = [module.eks]
}

# =============================================================================
# Kubernetes Storage Classes
# =============================================================================

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    type      = "gp3"
    encrypted = "true"
    kmsKeyId  = module.kms.key_arn
  }
  
  depends_on = [aws_eks_addon.ebs_csi]
}

# =============================================================================
# Cluster Autoscaler IAM Role
# =============================================================================

resource "aws_iam_role" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  name = "${local.name_prefix}-cluster-autoscaler"
  role = aws_iam_role.cluster_autoscaler.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# Cluster Autoscaler Helm Release
# =============================================================================

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.34.1"
  
  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }
  
  set {
    name  = "awsRegion"
    value = var.aws_region
  }
  
  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler.arn
  }
  
  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }
  
  depends_on = [module.eks]
}

