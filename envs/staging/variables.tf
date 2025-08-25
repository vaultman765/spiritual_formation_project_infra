# --- Ephemeral staging flags ---
variable "enable_apprunner_permissions" {
  type        = bool
  default     = true
  description = "If false, do not include App Runner permissions (for cost-savings mode)."
}
variable "staging_infra_enabled" {
  type        = bool
  default     = true
  description = "Master switch for staging compute/network (VPC, RDS, App Runner)."
}
variable "staging_rds_from_latest_snapshot" {
  type        = bool
  default     = false
  description = "On enable, restore staging RDS from latest manual snapshot instead of creating fresh."
}
variable "staging_low_cost" {
  type        = bool
  default     = false
  description = "Use low-cost mode (no NAT/interface endpoints; import task uses public subnets)."
}
variable "vpn_enabled" {
  type        = bool
  default     = false
  description = "Create the Client VPN when true; destroy/skip when false."
}

# --- Project/Environment Metadata ---
variable "aws_acct_num" {
  type        = string
  description = "AWS account number."
}
variable "env" {
  type        = string
  description = "Deployment environment (e.g., staging, prod)."
}
variable "name_prefix" {
  type        = string
  description = "Stable name prefix for staging resources (e.g., sf-staging)."
}
variable "project" {
  type        = string
  description = "Project name."
}
variable "region" {
  type        = string
  description = "AWS region."
}

# --- Networking ---
variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR block."
}
variable "client_vpn_server_cert_arn" {
  type        = string
  default     = "arn:aws:acm:us-east-1:756859458263:certificate/7c7c3042-872b-499d-9ec4-b47f3f711db4"
  description = "ARN for the VPN server certificate."
}
variable "nat_gateway_mode" {
  type        = string
  default     = "single"
  description = "NAT gateway mode: single | per_az | none."
}
variable "private_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
  description = "Private subnet CIDRs."
}
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
  description = "Public subnet CIDRs."
}

# --- GitHub/OIDC ---
variable "github_owner" {
  type        = string
  description = "GitHub organization/owner."
}
variable "github_refs" {
  type        = list(string)
  description = "GitHub refs for OIDC trust."
}
variable "github_repo" {
  type        = string
  description = "GitHub repository name."
}

# --- RDS/Database ---
variable "allocated_storage_gb" {
  type        = number
  description = "Allocated storage in GB."
}
variable "db_name" {
  type        = string
  description = "Database name."
}
variable "db_username" {
  type        = string
  description = "Database username."
}
variable "instance_class" {
  type        = string
  description = "RDS instance class."
}
variable "max_allocated_storage_gb" {
  type        = number
  description = "Max allocated storage in GB."
}
variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS."
}
variable "rds_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for RDS credentials."
}

# --- Secrets ---
variable "django_secret_arn" {
  type        = string
  description = "Secrets Manager ARN for Django secret key."
}

# --- S3/Buckets ---
variable "metadata_bucket" {
  type        = string
  description = "Name of the metadata S3 bucket."
}
variable "s3_bucket_name" {
  type        = string
  default     = "spiritual-formation-staging"
  description = "General S3 bucket name."
}

# --- App Runner ---
variable "apprunner_auto_deployments" {
  type        = bool
  description = "Enable AppRunner auto-deployments on new ECR image."
}
variable "apprunner_cpu" {
  type        = number
  description = "App Runner CPU units."
}
variable "apprunner_image_tag" {
  type        = string
  description = "App Runner image tag."
}
variable "apprunner_memory" {
  type        = number
  description = "App Runner memory in MB."
}
variable "apprunner_service_arn" {
  type        = string
  default     = ""
  description = "Exact App Runner service ARN (preferred when available)."
}
variable "apprunner_service_name" {
  type        = string
  default     = "sf-staging-apprunner-svc"
  description = "AppRunner Service Name."
}
variable "ecr_repo_name" {
  type        = string
  default     = "spiritual-formation-backend"
  description = "ECR repository name to push/pull."
}

# --- Web/Domain ---
variable "api_domain_name" {
  type        = string
  description = "API domain name."
}
variable "frontend_domain_name" {
  type        = string
  description = "Frontend domain name."
}
variable "mwc_sources" {
  type        = list(string)
  description = "Sources for the meditationwithchrist redirect."
}
variable "redirect_hosted_zone_id" {
  type        = string
  description = "Hosted zone ID for the redirect domain."
}
variable "redirect_root_domain_name" {
  type        = string
  default     = "meditationwithchrist.com"
  description = "Root domain for redirect."
}
variable "root_domain_name" {
  type        = string
  default     = "catholicmentalprayer.com"
  description = "Root domain name."
}
variable "static_admin_alias" {
  type        = string
  default     = null
  description = "FQDN for admin static CloudFront host (e.g. static.staging.catholicmentalprayer.com)."
}
variable "subdomain" {
  type        = string
  description = "Subdomain for environment."
}

# --- Security/Env Vars ---
variable "allowed_hosts" {
  type        = string
  description = "Comma-separated list of allowed hosts."
}
variable "cors_allowed_origins" {
  type        = string
  description = "Comma-separated list of CORS allowed origins."
}
variable "csrf_trusted_origins" {
  type        = string
  description = "Comma-separated list of CSRF trusted origins."
}

# Prod variables
variable "vpc_enable_flow_logs" {
  type        = bool
  default     = false
  description = "Enable VPC Flow Logs to CloudWatch Logs."
}

variable "vpc_flow_logs_retention_days" {
  type        = number
  default     = 30
  description = "Retention (days) for the VPC Flow Logs CloudWatch Log Group."
}

variable "vpc_flow_logs_kms_key_arn" {
  type        = string
  default     = ""
  description = "Optional KMS key ARN to encrypt the VPC Flow Logs log group. If empty, no KMS key is used."
}