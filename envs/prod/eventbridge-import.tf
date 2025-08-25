module "eventbridge_import" {
  source = "../../modules/eventbridge/import-job"

  project     = var.project
  env         = var.env
  name_prefix = var.name_prefix
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  # S3 bucket that emits ObjectCreated events
  metadata_bucket = module.s3.metadata_bucket_name

  # ECS bits from the module above
  cluster_arn             = module.ecs_import.cluster_arn
  task_definition_arn     = module.ecs_import.task_definition_arn
  task_role_arn           = module.ecs_import.task_role_arn
  task_execution_role_arn = module.ecs_import.execution_role_arn

  # Where to run the task
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs_tasks.id
}
