###########################################################
# GitHub OIDC role for PROD frontend deploy
###########################################################

module "ci_frontend_role_prod" {
  source = "../../modules/ci_frontend_policies"

  # Role name you’ll reference in GitHub vars
  role_name = "sf-frontend-deploy-prod"

  # Your repo
  github_org  = var.github_owner
  github_repo = var.github_repo

  # Target bucket & distribution from the prod frontend module
  bucket_name                = module.frontend_site_prod.bucket_name
  cloudfront_distribution_id = module.frontend_site_prod.distribution_id

  # Optional: extra policy statements if you ever need them
  # policy_extra_json = []
}
