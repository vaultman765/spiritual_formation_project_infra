###############################################
# GitHub OIDC roles for App Repo (staging/prod)
# - No hardcoded ARNs
# - ECR resolved by repository name
# - App Runner resolved by service ARN or service name
###############################################

locals {
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "Terraform"
  }
  include_apprunner = var.apprunner_service_arn != ""
}

# ---------- Role A: Metadata sync (S3 only) ----------
module "github_oidc_apprepo_metadata" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "spiritual-${var.env}-github-apprepo-metadata"
  oidc_provider_arn = module.github_oidc_infra.oidc_provider_arn

  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_refs  = var.github_refs
}

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
    resources = [
      "arn:aws:s3:::${var.metadata_bucket}/metadata/*",
      "arn:aws:s3:::${var.metadata_bucket}/checksum/*",
      "arn:aws:s3:::${var.metadata_bucket}/_triggers/*",
    ]
  }
}

resource "aws_iam_policy" "metadata_sync" {
  name   = "spiritual-${var.env}-metadata-sync"
  policy = data.aws_iam_policy_document.metadata_sync.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "metadata_sync" {
  role       = module.github_oidc_apprepo_metadata.role_name
  policy_arn = aws_iam_policy.metadata_sync.arn
}

# ---------- Role B: Build/Deploy (ECR + optional App Runner) ----------
module "github_oidc_apprepo_build" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "spiritual-${var.env}-github-apprepo-build"
  oidc_provider_arn = module.github_oidc_infra.oidc_provider_arn

  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_refs  = var.github_refs
}

# ECR repo by name → ARN/URI
data "aws_ecr_repository" "backend" {
  name = var.ecr_repo_name
}

data "aws_iam_policy_document" "app_build" {
  # ---- ECR login (always) ----
  statement {
    sid       = "ECRLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ---- ECR push/pull to the specific repo (always) ----
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
    resources = [data.aws_ecr_repository.backend.arn]
  }

  # ---- App Runner perms (optional) ----
  dynamic "statement" {
    for_each = local.include_apprunner ? [1] : []
    content {
      sid       = "StartandUpdateDeployment"
      effect    = "Allow"
      actions   = ["apprunner:StartDeployment", "apprunner:UpdateService", "apprunner:DescribeService"]
      resources = [var.apprunner_service_arn]
    }
  }

  dynamic "statement" {
    for_each = local.include_apprunner ? [1] : []
    content {
      sid       = "ReadOnlyList"
      effect    = "Allow"
      actions   = ["apprunner:ListServices", "apprunner:ListOperations"]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "app_build" {
  name   = "spiritual-${var.env}-app-build"
  policy = data.aws_iam_policy_document.app_build.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "app_build" {
  role       = module.github_oidc_apprepo_build.role_name
  policy_arn = aws_iam_policy.app_build.arn
}