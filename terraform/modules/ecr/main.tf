# =============================================================================
# ECR Module - Container Registries
# =============================================================================

resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)
  
  name                 = "${var.name_prefix}-${each.value}"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
  
  encryption_configuration {
    encryption_type = "AES256"
  }
  
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${each.value}"
  })
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each   = toset(var.repositories)
  repository = aws_ecr_repository.main[each.value].name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

