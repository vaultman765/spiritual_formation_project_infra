output "client_vpn_endpoint_id" {
  description = "Client VPN endpoint ID (null when disabled)"
  value       = var.vpn_enabled ? module.client_vpn[0].endpoint_id : null
}

output "client_vpn_sg_id" {
  description = "Security group attached to the Client VPN ENI (null when disabled)"
  value       = var.vpn_enabled ? module.client_vpn[0].sg_id : null
}
output "apprunner_service_arn" {
  value = module.apprunner.service_arn
}
output "apprunner_connector_sg_id" { value = aws_security_group.apprunner_connector.id }
output "ecs_tasks_sg_id" { value = aws_security_group.ecs_tasks.id }
output "metadata_bucket" { value = module.s3.metadata_bucket_name }
output "frontend_bucket" { value = module.s3.frontend_bucket_name }
output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnet_ids" { value = module.vpc.public_subnet_ids }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "rds_endpoint" { value = module.rds.db_endpoint }
output "rds_secret" { value = module.rds.secret_arn }
output "github_oidc_provider_arn" { value = module.github_oidc_infra.oidc_provider_arn }
output "ecr_backend_url" { value = module.ecr_backend.repo_url }
output "ecr_backend_arn" { value = module.ecr_backend.repo_arn }
output "apprepo_build_role_arn" { value = module.github_oidc_apprepo_build.role_arn }
output "apex_zone_id" {
  description = "Zone ID for catholicmentalprayer.com"
  value       = data.aws_route53_zone.catholic.zone_id
}



output "staging_frontend_bucket" {
  value       = module.frontend_staging.bucket_name
  description = "S3 bucket where you upload the built staging frontend."
}

output "staging_frontend_cf_domain" {
  value       = module.frontend_staging.distribution_domain
  description = "CloudFront domain name for staging."
}

output "staging_frontend_alias" {
  value       = module.frontend_staging.alias_record_fqdn
  description = "Route53 A/ALIAS record created for staging.catholicmentalprayer.com."
}
output "distribution_id" {
  value       = module.frontend_staging.distribution_id
  description = "CloudFront distribution ID for frontend."
}
output "static_admin_cf_domain" {
  value       = module.static_admin_staging.distribution_domain
  description = "CloudFront domain for static admin host."
}

output "static_admin_alias" {
  value       = module.static_admin_staging.alias_record_fqdn
  description = "Route53 alias record for static admin host."
}

output "static_admin_distribution_id" {
  value       = module.static_admin_staging.distribution_id
  description = "CloudFront distribution ID for static admin host."
}
output "apprepo_metadata_role_arn" {
  value = module.github_oidc_apprepo_metadata.role_arn
}
output "frontend_ci_role_arn" {
  value       = module.ci_frontend_role_staging.role_arn
  description = "Use this ARN in GitHub Actions (AWS_ROLE_ARN_STAGING)."
}
output "static_acm_arn" {
  value       = module.route53_acm_static_staging.certificate_arn
  description = "ACM ARN for static.staging.catholicmentalprayer.com"
}
output "eventbridge_rule_name" {
  value       = module.eventbridge_import.rule_name
  description = "EventBridge rule that triggers the import task."
}
output "eventbridge_role_arn" {
  value       = module.eventbridge_import.role_arn
  description = "IAM role EventBridge assumes to run the ECS task."
}
output "vpc_endpoints_sg_id" { value = var.staging_infra_enabled ? module.vpc_endpoints[0].sg_id : null }
output "vpce_secretsmanager_id" { value = var.staging_infra_enabled ? module.vpc_endpoints[0].secretsmanager_endpoint_id : null }
output "vpce_ecr_api_id" { value = var.staging_infra_enabled ? module.vpc_endpoints[0].ecr_api_endpoint_id : null }
output "vpce_ecr_dkr_id" { value = var.staging_infra_enabled ? module.vpc_endpoints[0].ecr_dkr_endpoint_id : null }
output "vpce_logs_id" { value = var.staging_infra_enabled ? module.vpc_endpoints[0].logs_endpoint_id : null }