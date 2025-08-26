variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "name_prefix" { type = string }

# ---- Metadata sync ----
variable "metadata_role_name" { type = string }
variable "metadata_bucket" { type = string }
# Defaults match your current prefixes exactly
variable "metadata_prefixes" {
  type    = list(string)
  default = ["metadata/", "checksum/", "_triggers/"]
}

# ---- Build/deploy ----
variable "build_role_name" { type = string }
variable "ecr_repository_arn" { type = string }
variable "apprunner_service_arn" {
  type    = string
  default = ""
}

# ---- Execution role (App Runner / ECS execution) ----
variable "execution_role_name" {
  type    = string
  default = ""
}
variable "execution_role_arn" {
  type    = string
  default = ""
}

# ---- Task role (code running in container) ----
variable "task_role_name" {
  type    = string
  default = ""
}
variable "task_role_arn" {
  type    = string
  default = ""
}

# Allow multiple secrets (RDS + Django), not just one
variable "secret_arns" {
  type        = list(string)
  description = "Secrets Manager ARNs that CI needs to read (can be empty)"
  default     = []
}
