###############################################
# GitHub OIDC role for App Repo (PROD) — Metadata sync
# - Trusts the same OIDC provider (from staging remote state)
# - Grants only S3 RW to specific prefixes in the prod metadata bucket
###############################################
module "github_oidc_apprepo_metadata" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "${var.name_prefix}-github-apprepo-metadata" # sf-prod-github-apprepo-metadata
  oidc_provider_arn = data.terraform_remote_state.staging.outputs.github_oidc_provider_arn

  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_refs  = var.github_refs # e.g. ["refs/heads/main","refs/heads/release/*","refs/tags/v*"]
}

# Reuse the same module used in staging to attach the least‑priv S3 policy
module "ci_app_policies_metadata_only" {
  source = "../../modules/ci_app_policies"

  project     = var.project
  env         = var.env
  region      = var.region
  name_prefix = var.name_prefix

  # metadata role to attach S3 policy to:
  metadata_role_name = module.github_oidc_apprepo_metadata.role_name

  # S3 bucket/prefixes for metadata sync:
  metadata_bucket = module.s3.metadata_bucket_name
  # metadata_prefixes = ["metadata/", "checksum/", "_triggers/"] # optional override

  # No build role / ECR / App Runner in this call:
  build_role_name       = null
  ecr_repository_arn    = null
  apprunner_service_arn = null

  # No secrets needed for metadata-only role:
  secret_arns = []
}