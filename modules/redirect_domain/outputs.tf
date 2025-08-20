output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CloudFront distribution ID."
}
output "distribution_domain" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront domain for the redirect."
}
output "certificate_arn" {
  value       = aws_acm_certificate_validation.cert.certificate_arn
  description = "Validated ACM cert ARN (us-east-1)."
}
output "aliases" {
  value       = var.from_domains
  description = "All source domains covered by the redirect."
}