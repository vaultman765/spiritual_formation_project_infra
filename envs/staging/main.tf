locals {
  # Prefer explicit var.name_prefix; otherwise fall back to <project>-<env>
  name_prefix = length(trim(var.name_prefix, " ")) > 0 ? var.name_prefix : "${var.project}-${var.env}"

  # Standardized names for CI lookups
  names = {
    vpc_name               = "${local.name_prefix}-vpc"
    rds_identifier         = "${local.name_prefix}-db"
    apprunner_service_name = "${local.name_prefix}-apprunner"
  }

  # Common tags
  common_tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

module "vpc" {
  source               = "../../modules/vpc"
  project              = var.project
  env                  = var.env
  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  # Wire kill-switch & cost mode
  enabled          = var.staging_infra_enabled
  nat_gateway_mode = var.staging_low_cost ? "none" : "single"

  # Nice naming/tags
  name_prefix = local.name_prefix
  tags        = local.common_tags
}
