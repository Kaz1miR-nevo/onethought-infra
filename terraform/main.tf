# =============================================================================
# OneThought Infrastructure - Main Terraform Configuration
# =============================================================================
# This file orchestrates the complete AWS infrastructure for OneThought.
# 
# Resources created:
# - VPC with public/private subnets
# - EKS Cluster with managed node groups
# - ECR repositories for container images
# - IAM roles and policies
# - AWS Load Balancer Controller
# - CloudWatch logging
# - KMS encryption keys
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote state configuration - uncomment and configure for production
  # backend "s3" {
  #   bucket         = "onethought-terraform-state"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = "eu-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

# =============================================================================
# Provider Configuration
# =============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "OneThought"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Repository  = "onethought-infra"
    }
  }
}

# Kubernetes provider - configured after EKS cluster creation
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.aws_region
    ]
  }
}

# Helm provider for installing charts
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name,
        "--region",
        var.aws_region
      ]
    }
  }
}

# =============================================================================
# Data Sources
# =============================================================================

# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get available AZs in the region
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# Local Variables
# =============================================================================

locals {
  # Naming convention: project-environment-resource
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Use first 3 AZs for high availability
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  # EKS cluster name
  cluster_name = "${local.name_prefix}-eks"
  
  # VPC CIDR blocks
  vpc_cidr = var.vpc_cidr
  
  # Calculate subnet CIDRs
  public_subnets  = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 4, i)]
  private_subnets = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 4, i + 4)]
}

# =============================================================================
# Modules
# =============================================================================

# VPC Module - Network infrastructure
module "vpc" {
  source = "./modules/vpc"

  name_prefix     = local.name_prefix
  vpc_cidr        = local.vpc_cidr
  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  environment     = var.environment
  cluster_name    = local.cluster_name
  
  tags = local.common_tags
}

# EKS Module - Kubernetes cluster
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.kubernetes_version
  
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  # Node group configuration
  node_groups = var.node_groups
  
  # Enable OIDC for service accounts
  enable_irsa = true
  
  # CloudWatch logging
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  environment = var.environment
  tags        = local.common_tags

  depends_on = [module.vpc]
}

# ECR Module - Container registries
module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  
  repositories = [
    "frontend",
    "backend"
  ]
  
  # Image retention policy
  image_retention_count = var.environment == "prod" ? 30 : 10
  
  # Enable image scanning
  scan_on_push = true
  
  tags = local.common_tags
}

# ALB Controller Module - AWS Load Balancer Controller
module "alb_controller" {
  source = "./modules/alb-controller"

  cluster_name                = module.eks.cluster_name
  cluster_oidc_provider_arn   = module.eks.oidc_provider_arn
  cluster_oidc_issuer_url     = module.eks.oidc_issuer_url
  
  vpc_id = module.vpc.vpc_id
  
  tags = local.common_tags

  depends_on = [module.eks]
}

# KMS Module - Encryption keys
module "kms" {
  source = "./modules/kms"

  name_prefix = local.name_prefix
  environment = var.environment
  
  # Key administrators
  key_administrators = var.key_administrators
  
  tags = local.common_tags
}

# Secrets Manager - Application secrets
module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  environment = var.environment
  kms_key_id  = module.kms.key_id
  
  tags = local.common_tags
}

# WAF Module - Web Application Firewall (Production only)
module "waf" {
  source = "./modules/waf"
  count  = var.environment == "prod" ? 1 : 0

  name_prefix = local.name_prefix
  environment = var.environment
  
  # Rate limiting rules
  rate_limit = var.waf_rate_limit
  
  # Enable AWS managed rules
  enable_aws_managed_rules = true
  
  tags = local.common_tags
}

# =============================================================================
# OIDC Provider for GitHub Actions
# =============================================================================

# This allows GitHub Actions to authenticate to AWS without storing credentials
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = ["sts.amazonaws.com"]
  
  # GitHub's OIDC thumbprint
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  
  tags = local.common_tags
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${local.name_prefix}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = local.common_tags
}

# Policy for GitHub Actions to push to ECR
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "${local.name_prefix}-github-actions-ecr"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

# Policy for GitHub Actions to access EKS
resource "aws_iam_role_policy" "github_actions_eks" {
  name = "${local.name_prefix}-github-actions-eks"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi"
        ]
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

# =============================================================================
# CloudWatch Log Groups
# =============================================================================

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/eks/${local.cluster_name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = module.kms.key_arn
  
  tags = local.common_tags
}

