terraform {
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

locals {
  exec_role_name = var.execution_role_name != "" ? var.execution_role_name : element(reverse(split("/", var.execution_role_arn)), 0)
  task_role_name = var.task_role_name != "" ? var.task_role_name : element(reverse(split("/", var.task_role_arn)), 0)
}

# ---------- Metadata Sync (S3; no CloudFront, to preserve current behavior) ----------
data "aws_iam_policy_document" "metadata_sync" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.metadata_bucket}"]
  }
  statement {
    sid = "ObjectRW"
    actions = [
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:AbortMultipartUpload", "s3:ListMultipartUploadParts", "s3:ListBucketMultipartUploads"
    ]
    resources = [for p in var.metadata_prefixes : "arn:aws:s3:::${var.metadata_bucket}/${p}*"]
  }
}

resource "aws_iam_policy" "metadata_sync" {
  name   = "${var.name_prefix}-metadata-sync"
  policy = data.aws_iam_policy_document.metadata_sync.json
}

resource "aws_iam_role_policy_attachment" "metadata_sync" {
  role       = var.metadata_role_name
  policy_arn = aws_iam_policy.metadata_sync.arn
}

# ---------- App Build (ECR + optional App Runner) ----------
data "aws_iam_policy_document" "app_build" {
  # ECR login
  statement {
    sid       = "ECRLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ECR push/pull to specific repo
  statement {
    sid = "ECRPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [var.ecr_repository_arn]
  }

  # Optional App Runner controls
  dynamic "statement" {
    for_each = var.apprunner_service_arn != "" ? [1] : []
    content {
      sid       = "StartandUpdateDeployment"
      actions   = ["apprunner:StartDeployment", "apprunner:UpdateService", "apprunner:DescribeService"]
      resources = [var.apprunner_service_arn]
    }
  }
  dynamic "statement" {
    for_each = var.apprunner_service_arn != "" ? [1] : []
    content {
      sid       = "ReadOnlyList"
      actions   = ["apprunner:ListServices", "apprunner:ListOperations"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "app_build" {
  name   = "${var.name_prefix}-app-build"
  policy = data.aws_iam_policy_document.app_build.json
}

resource "aws_iam_role_policy_attachment" "app_build" {
  role       = var.build_role_name
  policy_arn = aws_iam_policy.app_build.arn
}

# -------------------- Read Secrets (execution + task roles) -------------------

# Execution role (pulls secrets for injection)
data "aws_iam_policy_document" "exec_read_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secret_arns
  }
  # Preserve your KMS ViaService condition
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "exec_read_secrets" {
  name   = "${var.name_prefix}-exec-read-secrets"
  policy = data.aws_iam_policy_document.exec_read_secrets.json
}

resource "aws_iam_role_policy_attachment" "exec_read_secrets_attach" {
  role       = local.exec_role_name
  policy_arn = aws_iam_policy.exec_read_secrets.arn
}

# Task role (code in container)
data "aws_iam_policy_document" "task_read_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secret_arns
  }
  statement {
    actions   = ["kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "task_read_secrets" {
  name   = "${var.name_prefix}-task-read-secrets"
  policy = data.aws_iam_policy_document.task_read_secrets.json
}

resource "aws_iam_role_policy_attachment" "task_read_secrets_attach" {
  role       = local.task_role_name
  policy_arn = aws_iam_policy.task_read_secrets.arn
}