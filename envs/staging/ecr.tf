module "ecr_backend" {
  source          = "../../modules/ecr"
  repository_name = var.ecr_repo_name
}
