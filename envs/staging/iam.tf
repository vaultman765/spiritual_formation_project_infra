# OIDC + Terraform (infra repo) role
module "github_oidc_infra" {
  source = "../../modules/iam/github_oidc"

  project = var.project
  env     = var.env

  github_owner = var.github_owner
  github_repo  = var.github_repo

  # allow main pushes and PR plan runs
  github_refs = ["refs/heads/main", "refs/pull/*/merge"]

  # keep true while bootstrapping; we'll reduce later
  attach_admin_policy = true
}

