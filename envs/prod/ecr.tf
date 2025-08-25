module "ecr_backend" {
  source               = "../../modules/ecr"
  repository_name      = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
}