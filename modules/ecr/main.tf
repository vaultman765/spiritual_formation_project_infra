resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability
  image_scanning_configuration { scan_on_push = var.scan_on_push }
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }
}

# Keep the repo tidy: expire untagged images after 7 days
resource "aws_ecr_lifecycle_policy" "ttl" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Expire untagged after 7 days",
      selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 7 },
      action       = { type = "expire" }
    }]
  })
}
