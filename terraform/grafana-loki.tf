# =============================================================================
# OneThought Infrastructure - Monitoring Stack (Grafana + Loki + Prometheus)
# =============================================================================
# This file provisions the monitoring infrastructure on AWS including:
# - S3 bucket for Loki log storage
# - IAM roles for monitoring services
# - Helm releases for the monitoring stack
# =============================================================================

# =============================================================================
# S3 Bucket for Loki Logs
# =============================================================================

resource "aws_s3_bucket" "loki" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = "${local.name_prefix}-loki-logs-${data.aws_caller_identity.current.account_id}"
  
  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-loki-logs"
    Purpose = "Loki log storage"
  })
}

resource "aws_s3_bucket_versioning" "loki" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id
  
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms.key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id
  
  rule {
    id     = "log-retention"
    status = "Enabled"
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = var.environment == "prod" ? 365 : 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "loki" {
  count  = var.enable_monitoring ? 1 : 0
  bucket = aws_s3_bucket.loki[0].id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# IAM Role for Loki
# =============================================================================

resource "aws_iam_role" "loki" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name_prefix}-loki"
  
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
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:monitoring:loki"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "loki" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name_prefix}-loki"
  role  = aws_iam_role.loki[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.loki[0].arn,
          "${aws_s3_bucket.loki[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = module.kms.key_arn
      }
    ]
  })
}

# =============================================================================
# IAM Role for Grafana (for CloudWatch integration)
# =============================================================================

resource "aws_iam_role" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name_prefix}-grafana"
  
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
            "${replace(module.eks.oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:monitoring:grafana"
          }
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "grafana" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${local.name_prefix}-grafana"
  role  = aws_iam_role.grafana[0].id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# =============================================================================
# Prometheus Stack (kube-prometheus-stack)
# =============================================================================

resource "helm_release" "prometheus" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"
  
  values = [
    templatefile("${path.module}/helm-values/prometheus-values.yaml", {
      environment            = var.environment
      grafana_admin_password = var.grafana_admin_password
      grafana_role_arn       = aws_iam_role.grafana[0].arn
      storage_class          = kubernetes_storage_class.gp3.metadata[0].name
    })
  ]
  
  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    kubernetes_storage_class.gp3
  ]
}

# =============================================================================
# Loki Stack
# =============================================================================

resource "helm_release" "loki" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "5.41.4"
  
  values = [
    templatefile("${path.module}/helm-values/loki-values.yaml", {
      environment     = var.environment
      loki_role_arn   = aws_iam_role.loki[0].arn
      s3_bucket       = aws_s3_bucket.loki[0].bucket
      aws_region      = var.aws_region
      storage_class   = kubernetes_storage_class.gp3.metadata[0].name
    })
  ]
  
  depends_on = [
    module.eks,
    kubernetes_namespace.monitoring,
    aws_s3_bucket.loki
  ]
}

# =============================================================================
# Promtail (Log collector)
# =============================================================================

resource "helm_release" "promtail" {
  count      = var.enable_monitoring ? 1 : 0
  name       = "promtail"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.15.3"
  
  values = [
    templatefile("${path.module}/helm-values/promtail-values.yaml", {
      loki_url = "http://loki-gateway.monitoring.svc.cluster.local"
    })
  ]
  
  depends_on = [
    helm_release.loki
  ]
}

# =============================================================================
# Outputs
# =============================================================================

output "loki_bucket_name" {
  description = "S3 bucket name for Loki logs"
  value       = var.enable_monitoring ? aws_s3_bucket.loki[0].bucket : null
}

output "grafana_role_arn" {
  description = "IAM role ARN for Grafana"
  value       = var.enable_monitoring ? aws_iam_role.grafana[0].arn : null
}

output "loki_role_arn" {
  description = "IAM role ARN for Loki"
  value       = var.enable_monitoring ? aws_iam_role.loki[0].arn : null
}

