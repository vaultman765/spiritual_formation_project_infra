variable "project" { type = string }
variable "env" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }

# Stable naming/tagging
variable "name_prefix" {
  type        = string
  description = "Prefix for naming/tagging VPC resources (e.g., sf-staging)."
  default     = ""
}

# Toggle entire RDS stack (instance + subnet/param groups + SG)
variable "enabled" {
  type        = bool
  description = "Create RDS resources when true."
  default     = true
}

# Stable instance identifier so we can look up latest manual snapshot
variable "identifier" {
  type        = string
  description = "DB instance identifier (e.g., sf-staging-db). If empty, AWS auto-names and 'latest snapshot' lookup is disabled."
  default     = ""
}

# When (re)creating, restore from the latest MANUAL snapshot for this identifier
variable "restore_from_latest_snapshot" {
  type        = bool
  description = "If true and an identifier is set, restore from the latest manual snapshot of that instance."
  default     = false
}

# Or: explicitly pick a snapshot id (overrides 'latest' if set)
variable "restore_snapshot_identifier" {
  type        = string
  description = "Explicit snapshot identifier to restore from (takes precedence over restore_from_latest_snapshot)."
  default     = ""
}

# When destroying, force-create a final snapshot with this prefix + timestamp
variable "final_snapshot_prefix" {
  type        = string
  description = "Prefix used for the final snapshot name on destroy."
  default     = "sf-staging-final"
}


# Who may reach Postgres (we pass SG IDs from the env)
variable "allowed_sg_ids" {
  description = "List of security group IDs allowed to reach Postgres (tcp/5432)"
  type        = list(string)
  default     = []
}
variable "admin_cidr_blocks" {
  type    = list(string)
  default = []
} # optional: your IPs

# DB settings (cheap defaults for staging)
variable "engine_version" {
  type    = string
  default = "16.8"
}
variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}
variable "allocated_storage_gb" {
  type    = number
  default = 20
}
variable "max_allocated_storage_gb" {
  type    = number
  default = 100
}
variable "multi_az" {
  type    = bool
  default = false
}

variable "db_name" {
  type    = string
  default = "spiritualformation"
}
variable "db_username" {
  type    = string
  default = "sf_admin"
}

# Secrets Manager
variable "secret_name" {
  type    = string
  default = ""
  # if empty we compute: spiritual/<env>/rds/app
}

# Backups & protection (safe defaults for staging; override in prod)
variable "backup_retention_period" {
  type    = number
  default = 3
} # prod: 7+
variable "deletion_protection" {
  type    = bool
  default = false
} # prod: true

# CloudWatch Logs exports for RDS
# Checkov expects "postgresql" to be exported; add others as needed
variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql"]
}

# Query logging settings (parameter group)
#  - log_min_duration_statement: ms threshold (5000ms default to avoid noise)
#  - log_statement: none | ddl | mod | all
variable "rds_log_min_duration_ms" {
  type    = number
  default = 5000
}
variable "rds_log_statement" {
  type    = string
  default = "none"
} # prod can tune if desired

# CloudWatch retention for RDS log groups (days)
variable "log_retention_days" {
  type    = number
  default = 400
}

# Enhanced Monitoring
variable "monitoring_interval" {
  type    = number
  default = 0 # 0 = disabled; 1,5,10,15,30,60 seconds if enabled
}

variable "monitoring_role_arn" {
  type      = string
  default   = ""
  nullable  = true
  sensitive = false
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encrypting CloudWatch Logs"
  default     = null
}