output "role_name" {
  description = "The name of the IAM role created for GitHub OIDC"
  value       = aws_iam_role.this.name
}
output "role_arn" {
  description = "The ARN of the IAM role created for GitHub OIDC"
  value       = aws_iam_role.this.arn
}