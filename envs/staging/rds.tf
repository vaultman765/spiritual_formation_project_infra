locals {
  allowed_sg_ids = concat(
    [aws_security_group.apprunner_connector.id],
    [aws_security_group.ecs_tasks.id],
    var.vpn_enabled ? [module.client_vpn[0].sg_id] : []
  )
}

module "rds" {
  source = "../../modules/rds"

  project            = var.project
  env                = var.env
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_sg_ids = local.allowed_sg_ids

  # optional: add your workstation CIDR here while testing (remove later)
  admin_cidr_blocks = []

  db_name     = var.db_name
  db_username = var.db_username

  # keep cheap while POC; we can bump later
  instance_class           = var.instance_class
  allocated_storage_gb     = var.allocated_storage_gb
  max_allocated_storage_gb = var.max_allocated_storage_gb
  multi_az                 = var.multi_az

  # Ephemeral staging switches
  enabled                      = var.staging_infra_enabled
  identifier                   = local.names.rds_identifier
  restore_from_latest_snapshot = var.staging_rds_from_latest_snapshot
  restore_snapshot_identifier  = "" # optional explicit override
  final_snapshot_prefix        = "${var.name_prefix}-final"
}



