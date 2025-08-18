variable "project" {
  type = string
}
variable "env" {
  type = string
}
variable "region" {
  type = string
}
variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}
variable "nat_gateway_mode" {
  type    = string
  default = "single" # single | per_az | none
}
variable "client_vpn_server_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:756859458263:certificate/7c7c3042-872b-499d-9ec4-b47f3f711db4"
}
variable "rds_secret_arn" { type = string }
variable "django_secret_arn" { type = string }
variable "metadata_bucket" { type = string }
variable "apprunner_image_tag" { type = string }
variable "s3_bucket_name" {
  type    = string
  default = "spiritual-formation-staging"
}

variable "vpn_enabled" {
  description = "Create the Client VPN when true; destroy/skip when false."
  type        = bool
  default     = false
}
variable "github_owner" {
  type = string
}
variable "github_repo" {
  type = string
}
variable "aws_acct_num" {
  type = string
}
variable "github_refs" {
  type = list(string)
}
variable "root_domain_name" {
  type    = string
  default = "catholicmentalprayer.com"
}
variable "redirect_root_domain_name" {
  type    = string
  default = "meditationwithchrist.com"
}
variable "api_domain_name" {
  type = string
}
variable "allowed_hosts" {
  type = string
}
variable "cors_allowed_origins" {
  type = string
}
variable "csrf_trusted_origins" {
  type = string
}
variable "apprunner_cpu" {
  type = number
}
variable "apprunner_memory" {
  type = number
}
variable "frontend_domain_name" {
  type = string
}
variable "db_name" {
  type = string
}
variable "db_username" {
  type = string
}
variable "subdomain" {
  type = string
}
variable "instance_class" {
  type = string
}
variable "allocated_storage_gb" {
  type = number
}
variable "max_allocated_storage_gb" {
  type = number
}
variable "multi_az" {
  type = bool
}
variable "static_admin_alias" {
  type        = string
  description = "FQDN for admin static CloudFront host (e.g. static.staging.catholicmentalprayer.com)."
  default     = null
}
variable "mwc_sources" {
  type        = list(string)
  description = "Sources for the meditationwithchrist redirect"
}


# terraform-docs:begin:inputs
# Inputs (for ephemeral staging):
# - staging_infra_enabled: Master kill-switch for VPC/RDS/AppRunner in staging.
# - staging_rds_from_latest_snapshot: When enabling, restore RDS from latest manual snapshot.
# - staging_low_cost: If true, we'll avoid NAT & interface endpoints and run the import task in public subnets.
# - name_prefix: Stable prefix used to derive resource names (vpc/db/service); keeps CI lookups stable across rebuilds.
# terraform-docs:end:inputs

variable "staging_infra_enabled" {
  type        = bool
  description = "Master switch for staging compute/network (VPC, RDS, App Runner)."
  default     = true
}

variable "staging_rds_from_latest_snapshot" {
  type        = bool
  description = "On enable, restore staging RDS from latest manual snapshot instead of creating fresh."
  default     = false
}

variable "staging_low_cost" {
  type        = bool
  description = "Use low-cost mode (no NAT/interface endpoints; import task uses public subnets)."
  default     = false
}

variable "name_prefix" {
  type        = string
  description = "Stable name prefix for staging resources (e.g., sf-staging)."
  default     = "sf-staging"
}

variable "apprunner_auto_deployments" {
  type        = bool
  description = "Enable AppRunner auto-deployments on new ECR image."
}

variable "ecr_repo_name" {
  type        = string
  default     = "spiritual-formation-backend"
  description = "ECR repository name to push/pull"
}

variable "apprunner_service_arn" {
  type        = string
  default     = ""
  description = "Exact App Runner service ARN (preferred when available)."
}

variable "apprunner_service_name" {
  type        = string
  default     = "sf-staging-apprunner-svc"
  description = "AppRunner Service Name"
}

variable "enable_apprunner_permissions" {
  type        = bool
  default     = true
  description = "If false, do not include App Runner permissions (for cost-savings mode)."
}
