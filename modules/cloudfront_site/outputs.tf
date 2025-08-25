# terraform-docs:begin:outputs
# Outputs:
# - bucket_name: S3 bucket that stores the site assets.
# - distribution_id: CloudFront distribution ID.
# - distribution_domain: CloudFront domain (useful before DNS propagates).
# - alias_record_fqdn: Route53 A/ALIAS record FQDN for the site.
# terraform-docs:end:outputs

output "bucket_name" {
  value       = aws_s3_bucket.site.bucket
  description = "S3 bucket that stores the site assets."
}

output "distribution_id" {
  value       = aws_cloudfront_distribution.this.id
  description = "CloudFront distribution ID."
}

output "distribution_arn" {
  value       = aws_cloudfront_distribution.this.arn
  description = "CloudFront distribution ARN."
}

output "distribution_domain" {
  value       = aws_cloudfront_distribution.this.domain_name
  description = "CloudFront domain (useful before DNS propagates)."
}

output "alias_record_fqdn" {
  value       = aws_route53_record.alias.fqdn
  description = "Route53 A/ALIAS record FQDN for the site."
}
