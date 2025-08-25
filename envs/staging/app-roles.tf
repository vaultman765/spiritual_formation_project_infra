###############################################
# GitHub OIDC roles for App Repo (staging/prod)
# - No hardcoded ARNs
# - ECR resolved by repository name
# - App Runner resolved by service ARN or service name
###############################################

locals {
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "Terraform"
  }
  include_apprunner = var.apprunner_service_arn != ""
}

# ---------- Role A: Metadata sync (S3 only) ----------
module "github_oidc_apprepo_metadata" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "${var.name_prefix}-github-apprepo-metadata"
  oidc_provider_arn = module.github_oidc_infra.oidc_provider_arn
  github_owner      = var.github_owner
  github_repo       = var.github_repo
  github_refs       = var.github_refs
}

# ---------- Role B: Build/Deploy (ECR + optional App Runner) ----------
module "github_oidc_apprepo_build" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "${var.name_prefix}-github-apprepo-build"
  oidc_provider_arn = module.github_oidc_infra.oidc_provider_arn
  github_owner      = var.github_owner
  github_repo       = var.github_repo
  github_refs       = var.github_refs
}

# Replaces the deleted policy resources with a module
data "aws_ecr_repository" "backend" {
  name = var.ecr_repo_name
}

module "ci_app_policies" {
  source = "../../modules/ci_app_policies"

  project     = var.project
  env         = var.env
  region      = var.region
  name_prefix = var.name_prefix

  # Metadata sync
  metadata_role_name = module.github_oidc_apprepo_metadata.role_name
  metadata_bucket    = var.metadata_bucket
  # (optional) override prefixes:
  # metadata_prefixes = ["metadata/", "checksum/", "_triggers/"]

  # Build/deploy
  build_role_name       = module.github_oidc_apprepo_build.role_name
  ecr_repository_arn    = data.aws_ecr_repository.backend.arn
  apprunner_service_arn = var.apprunner_service_arn # "" keeps current behavior

  # Execution/task roles from your ECS import module (or wherever those roles are created)
  execution_role_arn = var.staging_infra_enabled ? module.ecs_import[0].execution_role_arn : null
  task_role_arn      = var.staging_infra_enabled ? module.ecs_import[0].task_role_arn : null

  # Secrets (RDS + Django)
  secret_arns = [
    var.rds_secret_arn,
    var.django_secret_arn,
  ]
}
