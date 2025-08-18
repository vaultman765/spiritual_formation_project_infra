locals {
  name = "${var.project}-${var.env}-import"
  tags = { Project = var.project, Env = var.env, Managed = "Terraform", Role = "ImportJob" }
}

# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${local.name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = local.tags
}

# Logs
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.name}"
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# Execution role (pulls image, writes logs)
resource "aws_iam_role" "execution" {
  name               = "${local.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role (app permissions)
resource "aws_iam_role" "task" {
  name               = "${local.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "task" {
  statement {
    sid = "S3MetadataRW"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::${var.metadata_bucket}"]
  }
  statement {
    sid = "S3ObjectsRW"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads"
    ]
    resources = [
      "arn:aws:s3:::${var.metadata_bucket}/*"
    ]
  }
  statement {
    sid       = "SecretsRead"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.rds_secret_arn, "${var.django_secret_arn}"]
  }
}

resource "aws_iam_policy" "task" {
  name   = "${local.name}-task-policy"
  policy = data.aws_iam_policy_document.task.json
}

resource "aws_iam_role_policy_attachment" "task_attach" {
  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task.arn
}

# Task definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  ephemeral_storage {
    size_in_gib = 21
  }
  volume {
    name = "metadata"
  }

  container_definitions = jsonencode([
    {
      name      = "import"
      image     = var.container_image
      essential = true
      command   = ["bash", "-lc", "/app/scripts/run_import_job.sh"]
      # run as root so the ephemeral volume is writable
      user = "0"
      environment = [
        { name = "DJANGO_SETTINGS_MODULE", value = "config.settings" },
        { name = "ENV", value = var.env },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "S3_BUCKET_NAME", value = var.metadata_bucket },
        { name = "METADATA_S3_PREFIX", value = "metadata" },
        { name = "CHECKSUM_S3_KEY", value = "checksum/.mental_prayer_checksums.json" },
        { name = "PYTHONUNBUFFERED", value = "1" },
        { name = "DB_SSL", value = "True" },
        { name = "DEBUG", value = "False" }
      ]
      secrets = [
        # map RDS secret JSON keys into env vars your Django expects
        { name = "DB_NAME", valueFrom = "${var.rds_secret_arn}:dbname::" },
        { name = "DB_USER", valueFrom = "${var.rds_secret_arn}:username::" },
        { name = "DB_PASSWORD", valueFrom = "${var.rds_secret_arn}:password::" },
        { name = "DB_HOST", valueFrom = "${var.rds_secret_arn}:host::" },
        { name = "DB_PORT", valueFrom = "${var.rds_secret_arn}:port::" },
        { name = "SECRET_KEY", valueFrom = "${var.django_secret_arn}:SECRET_KEY::" }
      ]
      mountPoints = [
        {
          sourceVolume  = "metadata"
          containerPath = "/app/metadata"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "import"
        }
      }
    }
  ])
  tags = local.tags
}

data "aws_caller_identity" "me" {}
