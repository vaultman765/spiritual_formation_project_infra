data "aws_caller_identity" "current" {}

module "kms_logs" {
  source       = "../../modules/kms/logs"
  name_prefix  = var.name_prefix
  region       = var.region
  aws_acct_num = var.aws_acct_num
  tags         = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

module "vpc" {
  source      = "../../modules/vpc"
  project     = var.project
  env         = var.env
  name_prefix = var.name_prefix

  cidr_block           = var.cidr_block
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  nat_gateway_mode     = var.nat_gateway_mode

  enable_flow_logs         = true
  flow_logs_retention_days = 30
  flow_logs_kms_key_arn    = module.kms_logs.kms_key_arn
}

module "vpc_endpoints" {
  source = "../../modules/vpc/endpoints"

  project     = var.project
  env         = var.env
  name_prefix = var.name_prefix
  region      = var.region

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Only allow from our workload SGs (preferred over entire VPC CIDR)
  allow_from_vpc_cidr = false
  allowed_sg_ids = {
    ecs_tasks           = aws_security_group.ecs_tasks.id
    apprunner_connector = aws_security_group.apprunner_connector.id
    sm_rotation         = aws_security_group.sm_rotation.id
  }

  # Turn on the endpoints we need for private egress
  enable_secretsmanager = true
  enable_ecr_api        = true
  enable_ecr_dkr        = true
  enable_logs           = true

  tags = { Project = var.project, Env = var.env, Managed = "Terraform", Purpose = "VpcEndpoints" }
}

module "logging" {
  source      = "../../modules/logging"
  name_prefix = var.name_prefix
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  bucket_name = "${var.name_prefix}-${var.region}-${data.aws_caller_identity.current.account_id}-logs"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.staging.outputs.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Match the exact list of refs (e.g., refs/heads/main)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for r in var.github_refs : "repo:${var.github_owner}/${var.github_repo}:${r}"]
    }
  }
}

module "cf_policies" {
  source      = "../../modules/cloudfront_policies"
  name_prefix = var.name_prefix
}