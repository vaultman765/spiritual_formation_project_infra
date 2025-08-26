variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "app_port" {
  type    = string
  default = "8000"
}

# Turn App Runner on/off
variable "enabled" {
  type        = bool
  description = "Create the App Runner service when true."
  default     = true
}

# Stable naming/tagging
variable "name_prefix" {
  type        = string
  description = "Prefix for naming/tagging VPC resources (e.g., sf-staging)."
  default     = ""
}

# Keep explicit control (you can set true if you prefer auto-rolls)
variable "auto_deployments_enabled" {
  type        = bool
  description = "Auto-deploy on new image tag."
}

# ECR url of the image used in AppRunner
variable "image_repository_url" {
  type        = string
  description = "ECR repository URL (ACCOUNT.dkr.ecr.../repo)"
}

# Tag of the image used in AppRunner
variable "image_tag" {
  type        = string
  description = "Image tag to deploy"
}

variable "cpu" {
  type    = number
  default = 1024
} # 1 vCPU
variable "memory" {
  type    = number
  default = 2048
} # 2 GB
variable "health_check_path" {
  type    = string
  default = "/health/"
}

variable "vpc_id" {
  type = string
}
variable "private_subnet_ids" {
  type = list(string)
}
# RDS security-group (so we can allow traffic from App Runner → DB)
variable "rds_sg_id" {
  type = string
}
variable "db_port" {
  type    = number
  default = 5432
}

variable "s3_bucket_name" {
  type = string
}

variable "rds_secret_arn" {
  type = string
}
variable "django_secret_arn" {
  type = string
}
variable "django_secret_is_json" {
  type    = bool
  default = true
}
variable "ssm_secret_arns" {
  type    = list(string)
  default = []
}
# Plain env as a map
variable "env_vars" {
  type        = map(string)
  description = "Runtime environment variables (plain text)"
  default     = {}
}
# Secrets as a map (value must be Secrets Manager 'name suffix' syntax)
# Example: arn:aws:secretsmanager:...:secret:my/secret:SECRET_KEY::
variable "env_secrets" {
  type        = map(string)
  description = "Runtime environment secrets"
  default     = {}
}
variable "log_kms_key_arn" {
  type = string
}
variable "log_retention_days" {
  type    = number
  default = 400
}