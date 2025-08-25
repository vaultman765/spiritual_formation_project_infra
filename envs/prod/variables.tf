variable "aws_acct_num" {
  type        = string
  description = "AWS account number."
}
variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "email" { type = string }

# Naming
variable "name_prefix" { type = string }

# VPC
variable "cidr_block" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "nat_gateway_mode" { type = string } # "single" | "per_az" | "none"

# GitHub OIDC / repo
variable "github_owner" { type = string }
variable "github_repo" { type = string }
variable "github_refs" { type = list(string) }

# Domains
variable "root_domain_name" { type = string }
variable "frontend_domain_name" { type = string }
variable "api_domain_name" { type = string }

# RDS
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage_gb" { type = number }
variable "max_allocated_storage_gb" { type = number }
variable "multi_az" { type = bool }
variable "backup_retention_period" { type = number }
variable "deletion_protection" { type = bool }
variable "identifier" { type = string } # stable DB identifier

# Secrets (preexisting or created by TF elsewhere)
variable "rds_secret_arn" { type = string }
variable "django_secret_arn" { type = string }

# App Runner / ECR
variable "ecr_repo_name" { type = string }
variable "apprunner_service_name" { type = string }
variable "apprunner_image_tag" { type = string }
variable "apprunner_cpu" { type = number }
variable "apprunner_memory" { type = number }
variable "apprunner_auto_deployments" { type = bool }

# Django/web
variable "allowed_hosts" { type = string }
variable "cors_allowed_origins" { type = string }
variable "csrf_trusted_origins" { type = string }

# Redirect
variable "redirect_root_domain_name" { type = string }
variable "mwc_sources" { type = list(string) }
variable "redirect_hosted_zone_id" {
  type        = string
  description = "Hosted zone ID for the redirect domain (meditationwithchrist.com)."
}

# s3
variable "metadata_bucket" {
  type        = string
  description = "Name of the metadata S3 bucket."
}

# ECS
variable "ecs_import_job_cpu" {
  type        = number
  description = "CPU allocation for the ECS for the import job"
}
variable "ecs_import_job_memory" {
  type        = number
  description = "Memory allocation for the ECS for the import job"
}
variable "ecs_import_job_log_retention" {
  type        = number
  description = "Log retention policy for the ECS for the import job"
}

# WAF
variable "enable_common_rule_set" {
  type        = bool
  description = "Enable the common rule set for WAF"
}
variable "enable_bad_inputs" {
  type        = bool
  description = "Enable bad inputs protection for WAF"
}
variable "enable_ip_reputation" {
  type        = bool
  description = "Enable IP reputation protection for WAF"
}

# SEO Verification
variable "google_verification" {
  type = list(string)
  description = "Google DNS verification for catholicmentalprayer.com"
}
variable "yandex_verification" {
  type = list(string)
  description = "Yandex DNS verification for catholicmentalprayer.com"
}