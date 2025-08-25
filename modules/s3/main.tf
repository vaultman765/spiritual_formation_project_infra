locals {
  metadata_bucket_name = var.metadata_bucket_name != "" ? var.metadata_bucket_name : "spiritual-formation-${var.env}"
  frontend_bucket_name = var.frontend_bucket_name != "" ? var.frontend_bucket_name : "spiritual-formation-frontend-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Managed = "Terraform"
  }
}

# --- metadata bucket ---
resource "aws_s3_bucket" "metadata" {
  bucket = local.metadata_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_ownership_controls" "metadata" {
  bucket = aws_s3_bucket.metadata.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "metadata" {
  bucket = aws_s3_bucket.metadata.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "metadata" {
  bucket = aws_s3_bucket.metadata.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "metadata" {
  bucket                  = aws_s3_bucket.metadata.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# send bucket events to EventBridge so we can match on ObjectCreated
resource "aws_s3_bucket_notification" "metadata_events" {
  bucket      = aws_s3_bucket.metadata.id
  eventbridge = true
}

# Allow CloudFront OAC to read objects from specific prefixes (adjust prefixes as needed)
resource "aws_s3_bucket_policy" "metadata_policy" {
  bucket = aws_s3_bucket.metadata.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1) Deny any non-HTTPS requests (affects everyone)
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.metadata.arn,
          "${aws_s3_bucket.metadata.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },

      # 2) Allow CloudFront OAC to read (ONLY this distribution)
      # If you have multiple origins/distributions that read this bucket,
      # either repeat this statement per distribution or use StringLike with an array.
      {
        Sid    = "AllowCloudFrontAccessOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject"]
        Resource = [
          # Restrict to the prefixes CloudFront actually serves (tighten if you like)
          "${aws_s3_bucket.metadata.arn}/*",
          "${aws_s3_bucket.metadata.arn}/django/static/*",
          "${aws_s3_bucket.metadata.arn}/django/media/*",
          "${aws_s3_bucket.metadata.arn}/images/*",
          "${aws_s3_bucket.metadata.arn}/docs/*"
        ]
        Condition = {
          StringLike = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_acct_num}:distribution/${var.static_admin_distribution_id}"
          }
        }
      }
    ]
  })
}

# Enable server access logging for the metadata bucket (only if a log bucket is provided)
resource "aws_s3_bucket_logging" "metadata" {
  count = var.log_bucket_name == null ? 0 : 1

  bucket        = aws_s3_bucket.metadata.id
  target_bucket = var.log_bucket_name
  target_prefix = "s3/metadata/"
}

# Basic lifecycle: expire non-current object versions after 15 days
resource "aws_s3_bucket_lifecycle_configuration" "metadata" {
  bucket = aws_s3_bucket.metadata.id

  rule {
    id     = "expire-noncurrent-15d"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 15
    }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# ---------- FRONTEND (DISABLED by default; cloudfront_site owns it) ----------
resource "aws_s3_bucket" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = local.frontend_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_versioning" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  count                   = var.create_frontend_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.frontend[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  count  = 0
  bucket = aws_s3_bucket.frontend[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1) Deny any non-HTTPS requests
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.frontend[0].arn,
          "${aws_s3_bucket.frontend[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },

      # 2) Allow CloudFront OAC to read SPA assets
      {
        Sid    = "AllowCloudFrontAccessOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = ["s3:GetObject"]
        Resource = [
          "${aws_s3_bucket.frontend[0].arn}/*"
        ]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${var.aws_acct_num}:distribution/${var.frontend_distribution_id}"
          }
        }
      }
    ]
  })
}

# Frontend: access logging (only when bucket is created and log bucket provided)
resource "aws_s3_bucket_logging" "frontend" {
  count = (var.create_frontend_bucket && var.log_bucket_name != null) ? 1 : 0

  bucket        = aws_s3_bucket.frontend[0].id
  target_bucket = var.log_bucket_name
  target_prefix = "s3/frontend/"
}

# Frontend: lifecycle (only when bucket is created)
resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  count  = var.create_frontend_bucket ? 1 : 0
  bucket = aws_s3_bucket.frontend[0].id

  rule {
    id     = "expire-noncurrent-15d"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration { noncurrent_days = 15 }
  }

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
