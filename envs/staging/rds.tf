locals {
  allowed_sg_ids = {
    apprunner_connector = aws_security_group.apprunner_connector.id
    ecs_tasks           = aws_security_group.ecs_tasks.id
    client_vpn          = var.vpn_enabled ? module.client_vpn[0].sg_id : null
  }
  # Remove any null values
  filtered_allowed_sg_ids = { for k, v in local.allowed_sg_ids : k => v if v != null }
}

module "rds" {
  source = "../../modules/rds"

  project            = var.project
  env                = var.env
  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  allowed_sg_ids = local.filtered_allowed_sg_ids

  # optional: add your workstation CIDR here while testing (remove later)
  admin_cidr_blocks = [] # e.g., ["x.x.x.x/32"]

  db_name     = var.db_name
  db_username = var.db_username

  # keep cheap while POC; we can bump later
  instance_class           = "db.t4g.micro"
  allocated_storage_gb     = 20
  max_allocated_storage_gb = 100
  multi_az                 = false

  # Ephemeral staging switches
  enabled                      = var.staging_infra_enabled
  identifier                   = local.names.rds_identifier
  restore_from_latest_snapshot = var.staging_rds_from_latest_snapshot
  restore_snapshot_identifier  = "" # optional explicit override
  final_snapshot_prefix        = "${var.name_prefix}-final"
}



