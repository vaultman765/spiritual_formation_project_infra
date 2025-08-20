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
