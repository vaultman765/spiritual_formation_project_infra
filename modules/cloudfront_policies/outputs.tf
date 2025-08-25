output "security_headers_policy_id" { value = aws_cloudfront_response_headers_policy.security.id }
output "static_cors_policy_id" {
  value = aws_cloudfront_response_headers_policy.static_cors.id
}