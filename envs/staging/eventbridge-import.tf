locals {
  import_image = "${module.ecr_backend.repo_url}:staging-latest"
}

module "ecs_import" {
  source = "../../modules/ecs_import_job"

  project            = var.project
  env                = var.env
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = aws_security_group.ecs_tasks.id

  container_image   = local.import_image
  aws_region        = var.region
  metadata_bucket   = module.s3.metadata_bucket_name
  rds_secret_arn    = module.rds.secret_arn
  django_secret_arn = var.django_secret_arn
}

# EventBridge rule for S3 ObjectCreated in metadata/ prefix
resource "aws_cloudwatch_event_rule" "s3_metadata_object_created" {
  name        = "${var.project}-${var.env}-metadata-trigger"
  description = "Fire ECS import once per sync via trigger files"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [module.s3.metadata_bucket_name] },
      "object" : { "key" : [{ "prefix" : "_triggers/" }] }
    }
  })
  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# Role EventBridge uses to run tasks & pass roles
resource "aws_iam_role" "events_to_ecs" {
  name               = "${var.project}-${var.env}-events-to-ecs"
  assume_role_policy = data.aws_iam_policy_document.events_assume.json
}

data "aws_iam_policy_document" "events_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "events_to_ecs" {
  statement {
    sid       = "RunTask"
    actions   = ["ecs:RunTask"]
    resources = [module.ecs_import.task_definition_arn]
  }
  statement {
    sid     = "PassRoles"
    actions = ["iam:PassRole"]
    resources = [
      module.ecs_import.task_role_arn,
      module.ecs_import.execution_role_arn
    ]
  }
}

resource "aws_iam_policy" "events_to_ecs" {
  name   = "${var.project}-${var.env}-events-to-ecs"
  policy = data.aws_iam_policy_document.events_to_ecs.json
}

resource "aws_iam_role_policy_attachment" "events_to_ecs_attach" {
  role       = aws_iam_role.events_to_ecs.name
  policy_arn = aws_iam_policy.events_to_ecs.arn
}

# Target: Run the Fargate task in our private subnets/SG
resource "aws_cloudwatch_event_target" "run_import_task" {
  rule      = aws_cloudwatch_event_rule.s3_metadata_object_created.name
  target_id = "ecs-run-task"
  arn       = module.ecs_import.cluster_arn
  role_arn  = aws_iam_role.events_to_ecs.arn

  ecs_target {
    task_definition_arn = module.ecs_import.task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    network_configuration {
      subnets          = module.vpc.private_subnet_ids
      security_groups  = [aws_security_group.ecs_tasks.id]
      assign_public_ip = false
    }
  }
}
