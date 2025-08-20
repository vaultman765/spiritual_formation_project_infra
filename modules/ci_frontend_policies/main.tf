data "aws_caller_identity" "me" {}

# ---- OIDC trust (GitHub Actions) ----
data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.me.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Allow all refs in this repo; tighten to specific branches/tags if you want
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
}

# ---- Least-priv policy for S3 sync + CloudFront invalidation ----
locals {
  bucket_arn     = "arn:aws:s3:::${var.bucket_name}"
  bucket_objects = "${local.bucket_arn}/*"
  cf_dist_arn    = "arn:aws:cloudfront::${data.aws_caller_identity.me.account_id}:distribution/${var.cloudfront_distribution_id}"
}

data "aws_iam_policy_document" "base" {
  statement {
    sid       = "S3WriteFrontend"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.bucket_arn]
  }
  statement {
    sid       = "S3ObjectRW"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:PutObjectAcl", "s3:DeleteObject", "s3:GetObject"]
    resources = [local.bucket_objects]
  }
  statement {
    sid       = "InvalidateCF"
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetDistribution", "cloudfront:GetDistributionConfig"]
    resources = [local.cf_dist_arn]
  }
}

# Optional: merge in any extra statements you pass
data "aws_iam_policy_document" "combined" {
  source_policy_documents = [data.aws_iam_policy_document.base.json]
  dynamic "statement" {
    for_each = var.policy_extra_json
    content {
      sid       = statement.value.Sid
      effect    = statement.value.Effect
      actions   = statement.value.Action
      resources = statement.value.Resource
    }
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.role_name}-policy"
  description = "Deploy frontend to ${var.bucket_name} and invalidate CloudFront ${var.cloudfront_distribution_id}"
  policy      = data.aws_iam_policy_document.combined.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
