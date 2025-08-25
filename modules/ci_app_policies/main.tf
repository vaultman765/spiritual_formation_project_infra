terraform {
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

locals {
  exec_role_name = var.execution_role_name != "" ? var.execution_role_name : (
    var.execution_role_arn != null ? element(reverse(split("/", var.execution_role_arn)), 0) : ""
  )
  task_role_name = var.task_role_name != "" ? var.task_role_name : (
    var.task_role_arn != null ? element(reverse(split("/", var.task_role_arn)), 0) : ""
  )
  nonempty_secret_arns = compact(var.secret_arns)
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

###############################################
# Build/Deploy policy (ECR + optional App Runner)
# Only create when both inputs are provided
###############################################
# data policy doc
data "aws_iam_policy_document" "app_build" {
  count = (var.ecr_repository_arn != null && var.build_role_name != null) ? 1 : 0

  # ---- ECR login (always, when enabled) ----
  statement {
    sid       = "ECRLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ---- ECR push/pull to the specific repo ----
  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
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

  # ---- Optional App Runner perms (only if provided) ----
  dynamic "statement" {
    for_each = (var.apprunner_service_arn != null) ? [1] : []
    content {
      sid       = "AppRunnerDeploy"
      effect    = "Allow"
      actions   = ["apprunner:StartDeployment", "apprunner:UpdateService", "apprunner:DescribeService"]
      resources = [var.apprunner_service_arn]
    }
  }
  dynamic "statement" {
    for_each = (var.apprunner_service_arn != null) ? [1] : []
    content {
      sid       = "AppRunnerList"
      effect    = "Allow"
      actions   = ["apprunner:ListServices", "apprunner:ListOperations"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "app_build" {
  count  = length(data.aws_iam_policy_document.app_build)
  name   = "${var.name_prefix}-app-build"
  policy = data.aws_iam_policy_document.app_build[0].json
  tags   = { Project = var.env, Env = var.env, Managed = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "app_build_attach" {
  count      = length(aws_iam_policy.app_build)
  role       = var.build_role_name
  policy_arn = aws_iam_policy.app_build[0].arn
}

# -------------------- Read Secrets (execution + task roles) -------------------

# Execution role (pulls secrets for injection)
data "aws_iam_policy_document" "exec_read_secrets" {
  statement {
    sid       = "SecretsManagerRead"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = local.nonempty_secret_arns
  }
  # Preserve your KMS ViaService condition
  statement {
    sid       = "KMSDecryptViaSM"
    effect    = "Allow"
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
  count       = length(local.nonempty_secret_arns) > 0 ? 1 : 0
  name        = "${var.name_prefix}-exec-read-secrets"
  description = "Allow CI/execution to read container-injected secrets"
  policy      = data.aws_iam_policy_document.exec_read_secrets.json
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "exec_read_secrets_attach" {
  count      = length(aws_iam_policy.exec_read_secrets) > 0 ? 1 : 0
  role       = var.execution_role_name != null ? var.execution_role_name : var.build_role_name
  policy_arn = aws_iam_policy.exec_read_secrets[0].arn
}

# Task role (code in container)
data "aws_iam_policy_document" "task_read_secrets" {
  statement {
    sid       = "SecretsManagerRead"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = local.nonempty_secret_arns
  }
  statement {
    sid       = "KMSDecryptViaSM"
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
  count       = length(local.nonempty_secret_arns) > 0 ? 1 : 0
  name        = "${var.name_prefix}-task-read-secrets"
  description = "Allow task role to read app secrets from Secrets Manager"
  policy      = data.aws_iam_policy_document.task_read_secrets
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "task_read_secrets_attach" {
  count      = length(aws_iam_policy.task_read_secrets) > 0 ? 1 : 0
  role       = var.task_role_name != null ? var.task_role_name : var.metadata_role_name
  policy_arn = aws_iam_policy.task_read_secrets[0].arn
}