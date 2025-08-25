############################################################
# CloudTrail (multi‑region) + S3 bucket + EventBridge delivery
############################################################

data "aws_caller_identity" "acct" {}

locals {
  ct_bucket_name = "${var.name_prefix}-${var.region}-${data.aws_caller_identity.acct.account_id}-cloudtrail"
  ct_log_prefix  = "AWSLogs/${data.aws_caller_identity.acct.account_id}"
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket = local.ct_bucket_name
  tags   = { Project = var.project, Env = var.env, Managed = "Terraform", Purpose = "CloudTrailLogs" }
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket                  = aws_s3_bucket.cloudtrail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# Required bucket policy so CloudTrail can write
data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid       = "AWSCloudTrailAclCheck"
    effect    = "Allow"
    principals {
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
  }

  statement {
    sid       = "AWSCloudTrailWrite"
    effect    = "Allow"
    principals {
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/${local.ct_log_prefix}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# The Trail – enabling this causes mgmt events to flow to EventBridge
resource "aws_cloudtrail" "main" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true

  # default event selectors are fine (Management events, Read+Write)
  # no CloudWatch Logs integration needed for EventBridge delivery

  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}
