locals {
  allowed_sg_ids = [
    aws_security_group.apprunner_connector.id,
    aws_security_group.ecs_tasks.id,
  ]
}

module "rds" {
  source = "../../modules/rds"

  project            = var.project
  env                = var.env
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_sg_ids = local.allowed_sg_ids

  # No direct admin IPs in prod (VPN only if later)
  admin_cidr_blocks = []

  # Core DB config from tfvars
  db_name     = var.db_name
  db_username = var.db_username

  instance_class           = var.instance_class
  allocated_storage_gb     = var.allocated_storage_gb
  max_allocated_storage_gb = var.max_allocated_storage_gb
  multi_az                 = var.multi_az

  monitoring_interval = 15
  monitoring_role_arn = aws_iam_role.rds_em.arn

  enabled               = true
  identifier            = var.identifier
  final_snapshot_prefix = "${var.name_prefix}-final"

  log_retention_days = var.log_retention_days
  kms_key_arn        = module.kms_logs.kms_key_arn
}
