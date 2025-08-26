locals {
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform", Role = "AppRunner" }
  secret_arns = compact([var.rds_secret_arn, var.django_secret_arn])
}

data "aws_caller_identity" "this" {}

# Log group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/apprunner/${var.name_prefix}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn
  tags              = local.tags
}

# Security group App Runner will use via the VPC connector (egress-only)
resource "aws_security_group" "apprunner" {
  name        = "${var.name_prefix}-apprunner-sg"
  description = "App Runner VPC egress"
  vpc_id      = var.vpc_id
  egress {
    description = "App Runner will use via the VPC connector (egress-only)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

# Allow App Runner → Postgres (ingress on the RDS SG, source = this SG)
resource "aws_vpc_security_group_ingress_rule" "rds_from_apprunner" {
  count                        = var.rds_sg_id != null ? 1 : 0
  description                  = "Allow Postgres from App Runner VPC connector"
  security_group_id            = var.rds_sg_id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
  referenced_security_group_id = aws_security_group.apprunner.id
}

# VPC Connector
resource "aws_apprunner_vpc_connector" "this" {
  count              = var.enabled ? 1 : 0
  vpc_connector_name = "${var.name_prefix}-apprunner-vpc"
  subnets            = var.private_subnet_ids
  security_groups    = [aws_security_group.apprunner.id]
  tags               = local.tags
}

# ---- ROLES ----

# Service role trust (App Runner service uses this to pull from ECR, etc.)
data "aws_iam_policy_document" "service_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service" {
  name               = "${var.name_prefix}-apprunner-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_trust.json
  tags               = local.tags
}

# Needed for ECR access, etc.
resource "aws_iam_role_policy_attachment" "service_ecr" {
  role       = aws_iam_role.service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# Instance role trust (your container runs under this)
data "aws_iam_policy_document" "instance_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "instance" {
  name               = "${var.name_prefix}-apprunner-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_trust.json
  tags               = local.tags
}

# Instance role inline policy
data "aws_iam_policy_document" "instance" {
  dynamic "statement" {
    for_each = length(local.secret_arns) > 0 ? [1] : []
    content {
      sid       = "SecretsRead"
      actions   = ["secretsmanager:GetSecretValue"]
      resources = local.secret_arns
    }
  }

  statement {
    sid       = "S3StaticList"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
  }

  statement {
    sid = "S3StaticRW"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }
  statement {
    sid = "KMSForS3"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [var.log_kms_key_arn]
  }
}

resource "aws_iam_policy" "instance" {
  count  = length(local.secret_arns) > 0 ? 1 : 0
  name   = "${var.name_prefix}-apprunner-instance-policy"
  policy = data.aws_iam_policy_document.instance.json
}

resource "aws_iam_role_policy_attachment" "instance_attach" {
  count      = length(local.secret_arns) > 0 ? 1 : 0
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance[0].arn
}

# ---- SERVICE ----

resource "aws_apprunner_service" "this" {
  count = var.enabled ? 1 : 0

  service_name = "${var.name_prefix}-apprunner-svc"
  tags         = local.tags

  source_configuration {
    auto_deployments_enabled = var.auto_deployments_enabled

    authentication_configuration {
      access_role_arn = aws_iam_role.service.arn
    }

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "${var.image_repository_url}:${var.image_tag}"

      image_configuration {
        port = var.app_port

        # Plain env
        runtime_environment_variables = {
          for k, v in var.env_vars : k => v
        }

        # Secrets (Secrets Manager ARNs with :KEY:: suffix)
        runtime_environment_secrets = {
          for k, v in var.env_secrets : k => v
        }
      }
    }
  }

  instance_configuration {
    instance_role_arn = aws_iam_role.instance.arn
    cpu               = var.cpu
    memory            = var.memory
  }

  network_configuration {
    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.this[0].arn
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = var.health_check_path
    healthy_threshold   = 1
    unhealthy_threshold = 5
    interval            = 10
    timeout             = 5
  }
  depends_on = [
    aws_iam_role.service,
    aws_iam_role_policy_attachment.service_ecr, # ← wait for policy to attach
  ]
}


