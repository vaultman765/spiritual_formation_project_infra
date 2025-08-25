output "log_bucket_name" {
  value       = aws_s3_bucket.logs.bucket
  description = "Name of the central logs bucket"
}
