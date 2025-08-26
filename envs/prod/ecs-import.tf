locals {
  import_image = "${module.ecr_backend.repo_url}:prod-latest"
}

module "ecs_import" {
  source = "../../modules/ecs_import_job"

  project            = var.project
  env                = var.env
  name_prefix        = var.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs_tasks.id

  container_image   = local.import_image
  aws_region        = var.region
  metadata_bucket   = module.s3.metadata_bucket_name
  rds_secret_arn    = var.rds_secret_arn
  django_secret_arn = var.django_secret_arn

  cpu                = var.ecs_import_job_cpu
  memory             = var.ecs_import_job_memory
  log_kms_key_arn    = module.kms_logs.kms_key_arn
  log_retention_days = var.log_retention_days
}
