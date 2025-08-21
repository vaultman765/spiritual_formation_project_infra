# Identity / account
output "account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS account ID"
}

# VPC
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "Prod VPC ID"
}
output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnets"
}
output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnets"
}

# Flow logs / KMS
output "vpc_flow_logs_log_group" {
  value       = "/aws/vpc/${var.name_prefix}/flow-logs"
  description = "CloudWatch Log Group name for VPC flow logs"
}
output "logs_kms_key_arn" {
  value       = module.kms_logs.kms_key_arn
  description = "KMS key used to encrypt CloudWatch Logs"
}

# Central logs bucket (target for CF/S3 access logging)
output "log_bucket_name" {
  value       = module.logging.log_bucket_name
  description = "Central logs S3 bucket"
}

# CF security headers policy (re-use for all distributions)
# output "cf_security_headers_policy_id" {
#   value       = module.cf_policies.security_headers_policy_id
#   description = "Response headers policy ID for CloudFront"
# }
