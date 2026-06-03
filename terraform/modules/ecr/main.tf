resource "aws_ecr_repository" "main" {
  count = var.create_repository ? 1 : 0

  name                 = "${var.name_prefix}-${var.repository_name}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

locals {
  ecr_repository_name = var.create_repository ? aws_ecr_repository.main[0].name : "${var.name_prefix}-${var.repository_name}"
}

resource "aws_ecr_lifecycle_policy" "main" {
  depends_on = var.create_repository ? [aws_ecr_repository.main] : []

  repository = local.ecr_repository_name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = { type = "expire" }
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
        action = { type = "expire" }
      }
    ]
  })
}
