###########################################################
# GitHub OIDC role for STAGING frontend deploy
###########################################################

module "ci_frontend_role_staging" {
  source = "../../modules/ci_frontend_policies"

  role_name   = "sf-frontend-deploy-staging"
  github_org  = var.github_owner
  github_repo = var.github_repo

  # Use the existing module outputs or known names:
  bucket_name                = module.frontend_staging.bucket_name
  cloudfront_distribution_id = module.frontend_staging.distribution_id

  # policy_extra_json = [] # optional
}

# terraform-docs:begin:outputs
# Outputs:
# - frontend_ci_role_arn: OIDC role ARN for staging frontend deploy.
# terraform-docs:end:outputs
