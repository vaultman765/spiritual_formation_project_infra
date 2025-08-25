output "metadata_sync_policy_arn" { value = aws_iam_policy.metadata_sync.arn }
output "app_build_policy_arn" {
  value = length(aws_iam_policy.app_build) > 0 ? aws_iam_policy.app_build[0].arn : null
}