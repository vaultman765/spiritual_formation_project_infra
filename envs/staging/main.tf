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

  # Naming/tags
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

module "vpc_endpoints" {
  source = "../../modules/vpc/endpoints"

  # identity / naming
  project     = var.project
  env         = var.env
  name_prefix = var.name_prefix
  region      = var.region

  # where to place the endpoints
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # keep behavior: allow 443 from entire VPC CIDR + explicit SGs
  allow_from_vpc_cidr = true
  allowed_sg_ids = {
    ecs_tasks = aws_security_group.ecs_tasks.id
    # if App Runner VPC connector should reach endpoints too, include it:
    # apprunner_connector = aws_security_group.apprunner_connector.id
  }

  tags = {
    Project = var.project
    Env     = var.env
    Managed = "Terraform"
    Purpose = "VpcEndpoints"
  }

  # preserve your low-cost toggle:
  # when true, skip interface endpoints and (elsewhere) run jobs via public subnets
  enable_secretsmanager = !var.staging_low_cost
  enable_ecr_api        = !var.staging_low_cost
  enable_ecr_dkr        = !var.staging_low_cost
  enable_logs           = !var.staging_low_cost
}

module "cf_policies" {
  source     = "../../modules/cloudfront_policies"
  name_prefix = var.name_prefix
}