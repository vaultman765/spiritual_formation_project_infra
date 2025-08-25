terraform {
  required_providers {
    time = {
      source = "hashicorp/time"
    }
  }
}

data "aws_region" "current" {}

locals {
  tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "Terraform"
  }
  # Parameter group family from engine major
  engine_major = regex("^\\d+", var.engine_version)
  family       = "postgres${local.engine_major}"
  secret_name  = var.secret_name != "" ? var.secret_name : "spiritual/${var.env}/rds/app"
}

# --- Networking
resource "aws_db_subnet_group" "this" {
  count      = var.enabled ? 1 : 0
  name       = "${var.name_prefix}-db-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = merge(local.tags, { Name = "${var.name_prefix}-db-subnets" })

  # Ensure the new subnet group is created before deleting the old one
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow Postgres from app runner + ecs + (optional) admin"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name_prefix}-rds-sg" })
}

# Allow from provided SGs (App Runner VPC connector SG and ECS tasks SG)
resource "aws_vpc_security_group_ingress_rule" "from_sgs" {
  count                        = var.enabled ? length(var.allowed_sg_ids) : 0
  security_group_id            = aws_security_group.rds[0].id
  referenced_security_group_id = var.allowed_sg_ids[count.index]
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "App/ECS access"
}

# Optional admin CIDR(s)
resource "aws_vpc_security_group_ingress_rule" "from_admin" {
  for_each          = var.enabled ? toset(var.admin_cidr_blocks) : []
  security_group_id = aws_security_group.rds[0].id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  description       = "Admin access"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  count             = var.enabled ? 1 : 0
  security_group_id = aws_security_group.rds[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

# --- Parameter group (enforce SSL)
resource "aws_db_parameter_group" "pg" {
  count       = var.enabled ? 1 : 0
  name        = "${var.name_prefix}-pg"
  family      = local.family
  description = "Params for ${var.name_prefix}"
  tags        = merge(local.tags, { Name = "${var.name_prefix}-pg" })

  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "immediate"
  }

  # Query logging (tunable via variables)
  parameter {
    name         = "log_min_duration_statement"
    value        = tostring(var.rds_log_min_duration_ms)
    apply_method = "immediate"
  }

  parameter {
    name         = "log_statement"
    value        = var.rds_log_statement
    apply_method = "immediate"
  }

  # Ensure the new PG is created before the old one is deleted
  lifecycle {
    create_before_destroy = true
  }
}

# --- Password & Secrets
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "!#$%&()*+,-.:;<=>?[]^_{|}~" # excludes / @ " and space
}

resource "aws_secretsmanager_secret" "db" {
  name = local.secret_name
  tags = local.tags
}

# --- RDS instance
resource "aws_db_instance" "this" {
  count = var.enabled ? 1 : 0

  identifier = var.identifier != "" ? var.identifier : null

  snapshot_identifier = (
    var.restore_snapshot_identifier != "" ? var.restore_snapshot_identifier :
    (var.restore_from_latest_snapshot && length(data.aws_db_snapshot.latest) > 0
      ? data.aws_db_snapshot.latest[0].id
    : null)
  )

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  parameter_group_name   = aws_db_parameter_group.pg[0].name

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_encrypted     = true

  publicly_accessible = false
  multi_az            = var.multi_az
  apply_immediately   = true

  # Guarantees groups exist before we modify the instance to use them
  depends_on = [
    aws_db_parameter_group.pg,
    aws_db_subnet_group.this,
  ]

  # Backups & protection (env-gated via variables)
  backup_retention_period = 3
  backup_window           = "22:00-23:00"
  maintenance_window      = "Mon:00:00-Mon:01:00"
  deletion_protection     = var.deletion_protection
  copy_tags_to_snapshot   = true

  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.final_snapshot_prefix}-${replace(time_static.final.rfc3339, ":", "-")}"

  # Export engine logs to CloudWatch (for Checkov CKV2_AWS_30)
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # (Optional but useful)
  performance_insights_enabled = false # prod can override to true later

  # Enhanced Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null



  tags = local.tags
}

# Secret value AFTER instance exists (includes host/port)
resource "aws_secretsmanager_secret_version" "db_current" {
  count     = var.enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.this[0].address
    port     = aws_db_instance.this[0].port
    dbname   = var.db_name
    username = var.db_username
    password = random_password.db.result
    sslmode  = "require"
  })
}

# Stable timestamp for final-snapshot naming
resource "time_static" "final" {
  rfc3339 = timestamp()
}

# Lookup latest manual snapshot
data "aws_db_snapshot" "latest" {
  count                  = var.restore_from_latest_snapshot && var.identifier != "" ? 1 : 0
  most_recent            = true
  db_instance_identifier = var.identifier
  snapshot_type          = "manual"
}

# Create log groups with explicit retention once the DB identifier is known.
# We only create them when identifier is set (your env passes it).
resource "aws_cloudwatch_log_group" "rds_postgresql" {
  count             = var.enabled && var.identifier != "" ? 1 : 0
  name              = "/aws/rds/instance/${var.identifier}/postgresql"
  retention_in_days = var.rds_log_retention_days
}