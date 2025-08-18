output "metadata_bucket_name" { value = aws_s3_bucket.metadata.bucket }
output "metadata_bucket_arn" { value = aws_s3_bucket.metadata.arn }
output "frontend_bucket_name" { value = var.create_frontend_bucket ? aws_s3_bucket.frontend[0].bucket : null }
output "frontend_bucket_arn" { value = var.create_frontend_bucket ? aws_s3_bucket.frontend[0].arn : null }
