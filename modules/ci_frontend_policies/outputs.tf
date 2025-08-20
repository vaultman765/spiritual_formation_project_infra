# terraform-docs:begin:outputs
# Outputs:
# - role_arn: ARN to use in GitHub Actions (role-to-assume).
# terraform-docs:end:outputs

output "role_arn" {
  value       = aws_iam_role.this.arn
  description = "OIDC role ARN for GitHub Actions"
}
