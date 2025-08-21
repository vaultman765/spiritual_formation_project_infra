terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

# EventBridge rule for S3 ObjectCreated in _triggers/ (bucket is an input)
resource "aws_cloudwatch_event_rule" "s3_metadata_object_created" {
  name        = "${var.name_prefix}-metadata-trigger"
  description = "Fire ECS import once per sync via trigger files"
  event_pattern = jsonencode({
    "source" : ["aws.s3"],
    "detail-type" : ["Object Created"],
    "detail" : {
      "bucket" : { "name" : [var.metadata_bucket] },
      "object" : { "key" : [{ "prefix" : "_triggers/" }] }
    }
  })
  tags = merge(var.tags, { Name = "${var.name_prefix}-metadata-trigger" })
}

# IAM role that EventBridge assumes
data "aws_iam_policy_document" "events_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "events_to_ecs" {
  name               = "${var.project}-${var.env}-events-to-ecs"
  assume_role_policy = data.aws_iam_policy_document.events_assume.json
  tags               = var.tags
}

# Permissions: RunTask + PassRole (execution + task roles)
data "aws_iam_policy_document" "events_to_ecs" {
  dynamic "statement" {
    for_each = var.task_definition_arn != null ? [var.task_definition_arn] : []
    content {
      sid       = "RunTask"
      actions   = ["ecs:RunTask"]
      resources = [statement.value]
    }
  }

  dynamic "statement" {
    for_each = length(compact([var.task_role_arn, var.task_execution_role_arn])) > 0 ? [1] : []
    content {
      sid     = "PassRoles"
      actions = ["iam:PassRole"]
      resources = compact([
        var.task_role_arn,
        var.task_execution_role_arn
      ])
      condition {
        test     = "StringEquals"
        variable = "iam:PassedToService"
        values   = ["ecs-tasks.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_policy" "events_to_ecs" {
  count  = (var.task_definition_arn != null || length(compact([var.task_role_arn, var.task_execution_role_arn])) > 0) ? 1 : 0
  name   = "${var.name_prefix}-events-to-ecs"
  policy = data.aws_iam_policy_document.events_to_ecs.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "events_to_ecs_attach" {
  count      = length(aws_iam_policy.events_to_ecs) > 0 ? 1 : 0
  role       = aws_iam_role.events_to_ecs.name
  policy_arn = aws_iam_policy.events_to_ecs[0].arn
}

# Target: run Fargate task in private subnets, no public IP (matches your current config)
resource "aws_cloudwatch_event_target" "run_import_task" {
  count = var.cluster_arn != null && var.task_definition_arn != null ? 1 : 0

  rule     = aws_cloudwatch_event_rule.s3_metadata_object_created.name
  arn      = var.cluster_arn
  role_arn = aws_iam_role.events_to_ecs.arn

  ecs_target {
    task_definition_arn = var.task_definition_arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"
    network_configuration {
      subnets          = var.private_subnet_ids
      security_groups  = [var.security_group_id]
      assign_public_ip = false
    }
    propagate_tags = "TASK_DEFINITION"
  }
}
