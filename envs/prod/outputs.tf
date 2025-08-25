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

output "ecr_backend_url" {
  value = module.ecr_backend.repo_url
}

output "ecr_backend_arn" {
  value = module.ecr_backend.repo_arn
}
output "github_oidc_provider_arn" {
  value       = data.terraform_remote_state.staging.outputs.github_oidc_provider_arn
  description = "OIDC provider ARN for GitHub"
}
output "metadata_bucket_name" {
  value       = module.s3.metadata_bucket_name
  description = "Prod metadata bucket name"
}
output "static_acm_arn" {
  value = module.route53_acm_static_prod.certificate_arn
}
output "static_admin_cf_domain" {
  value = module.static_admin_prod.distribution_domain
}
output "static_admin_alias" {
  value = module.static_admin_prod.alias_record_fqdn
}
output "static_admin_distribution_id" {
  value = module.static_admin_prod.distribution_id
}
output "import_cluster_arn" {
  value = module.ecs_import.cluster_arn
}
output "import_task_definition_arn" {
  value = module.ecs_import.task_definition_arn
}
output "import_task_role_arn" {
  value = module.ecs_import.task_role_arn
}
output "import_execution_role_arn" {
  value = module.ecs_import.execution_role_arn
}
output "import_event_rule_name" {
  value = module.eventbridge_import.rule_name
}
output "apprepo_metadata_role_arn" {
  value       = module.github_oidc_apprepo_metadata.role_arn
  description = "Use in GitHub Actions to sync metadata to prod."
}
output "apprunner_service_arn" {
  value       = module.apprunner.service_arn
  description = "Prod App Runner service ARN"
}
output "apprunner_vpc_connector_arn" {
  value       = module.apprunner.vpc_connector_arn
  description = "App Runner VPC connector ARN"
}
output "apprunner_custom_domain_status" {
  value       = aws_apprunner_custom_domain_association.api_prod.status
  description = "Should become ACTIVE after validation."
}
output "frontend_bucket_name" {
  value       = module.frontend_site_prod.bucket_name
  description = "S3 bucket to upload SPA build artifacts for prod."
}
output "frontend_distribution_id" {
  value       = module.frontend_site_prod.distribution_id
  description = "CloudFront distribution ID (use for invalidations)."
}
output "frontend_cf_domain" {
  value       = module.frontend_site_prod.distribution_domain
  description = "CloudFront domain for the SPA."
}
output "frontend_alias_record" {
  value       = module.frontend_site_prod.alias_record_fqdn
  description = "Route53 alias record FQDN."
}
output "frontend_ci_role_arn" {
  value       = module.ci_frontend_role_prod.role_arn
  description = "Use in GitHub Actions as ROLE_ARN_FRONTEND_PROD"
}
output "frontend_bucket_for_ci" {
  value       = module.frontend_site_prod.bucket_name
  description = "Upload SPA build here"
}
output "frontend_distribution_for_ci" {
  value       = module.frontend_site_prod.distribution_id
  description = "Use for CloudFront invalidations"
}
output "alerts_topic_arn" {
  value       = aws_sns_topic.waf_alerts.arn
  description = "SNS topic ARN for WAF alerts"
}
output "web_acl_arn" {
  value = aws_wafv2_web_acl.prod.arn
}
output "web_acl_name" {
  value = aws_wafv2_web_acl.prod.name
}
output "rds_secret" { value = module.rds.secret_arn }
output "cloudtrail_trail_arn" {
  value       = aws_cloudtrail.main.arn
  description = "CloudTrail trail ARN"
}
output "cloudtrail_bucket_name" {
  value       = aws_s3_bucket.cloudtrail.bucket
  description = "S3 bucket for CloudTrail logs"
}