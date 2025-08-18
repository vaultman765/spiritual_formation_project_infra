# terraform-docs:begin:outputs
# Outputs:
# - distribution_id: CloudFront distribution ID.
# - distribution_domain: CloudFront domain (useful for testing before DNS propagates).
# - alias_record_fqdn: Route 53 A/ALIAS record FQDN.
# terraform-docs:end:outputs

output "distribution_id" {
  value       = aws_cloudfront_distribution.static.id
  description = "CloudFront distribution ID."
}
output "distribution_domain" {
  value       = aws_cloudfront_distribution.static.domain_name
  description = "CloudFront domain name."
}
output "alias_record_fqdn" {
  value       = aws_route53_record.alias.fqdn
  description = "Route53 A/ALIAS record FQDN."
}
