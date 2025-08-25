locals {
  import_image = "${module.ecr_backend.repo_url}:staging-latest"
}

module "ecs_import" {
  source = "../../modules/ecs_import_job"

  count = var.staging_infra_enabled ? 1 : 0

  project            = var.project
  env                = var.env
  name_prefix        = var.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs_tasks.id

  container_image   = local.import_image
  aws_region        = var.region
  metadata_bucket   = module.s3.metadata_bucket_name
  rds_secret_arn    = module.rds.secret_arn
  django_secret_arn = var.django_secret_arn
}

module "eventbridge_import" {
  source = "../../modules/eventbridge/import-job"

  project     = var.project
  env         = var.env
  name_prefix = var.name_prefix
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  metadata_bucket = module.s3.metadata_bucket_name

  # From ecs_import module outputs
  cluster_arn             = var.staging_infra_enabled ? module.ecs_import[0].cluster_arn : null
  task_definition_arn     = var.staging_infra_enabled ? module.ecs_import[0].task_definition_arn : null
  task_role_arn           = var.staging_infra_enabled ? module.ecs_import[0].task_role_arn : null
  task_execution_role_arn = var.staging_infra_enabled ? module.ecs_import[0].execution_role_arn : null

  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs_tasks.id
}
