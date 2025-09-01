terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # CloudFront needs us-east-1 provider passed from parent
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  # Turn domain (e.g. staging.example.com) into a safe bucket name if none provided
  derived_bucket = replace(lower(var.domain_name), ".", "-")
  bucket_name    = var.bucket_name != "" ? var.bucket_name : "${local.derived_bucket}-site"
}

# ---------------- S3 (private) ----------------
resource "aws_s3_bucket" "site" {
  # checkov:skip=CKV_AWS_145 reason="Public website buckets behind CloudFront OAC; AES256 avoids CF/KMS coupling."
  bucket = local.bucket_name
  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_logging" "site" {
  count = var.log_bucket_name == null ? 0 : 1

  bucket        = aws_s3_bucket.site.id
  target_bucket = var.log_bucket_name
  target_prefix = "s3/site/${var.domain_name}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    id     = "expire-noncurrent-7d"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration { noncurrent_days = 7 }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "site_events" {
  bucket      = aws_s3_bucket.site.id
  eventbridge = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule { object_ownership = "BucketOwnerEnforced" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------- CloudFront OAI ----------------
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.domain_name}"
}

# Bucket policy to let CloudFront OAI read objects
data "aws_iam_policy_document" "site_read" {
  statement {
    sid       = "AllowCloudFrontRead"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_read.json
}

# ---------------- CloudFront ----------------
resource "aws_cloudfront_distribution" "this" {
  # checkov:skip=CKV2_AWS_47 reason="Log4j protection implemented via AWSManagedRulesKnownBadInputsRuleSet with Log4JRCE rule_action_override and AWSManagedRulesAnonymousIpList"
  provider = aws.us_east_1

  enabled         = true
  is_ipv6_enabled = true
  comment         = var.domain_name

  aliases = [var.domain_name]

  web_acl_id = var.web_acl_arn

  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-origin-${var.domain_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-origin-${var.domain_name}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.append_index_html.arn
    }

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    min_ttl     = var.min_ttl
    default_ttl = var.default_ttl
    max_ttl     = var.max_ttl

    response_headers_policy_id = var.response_headers_policy_id
}

  dynamic "custom_error_response" {
    for_each = var.spa_mode ? [403, 404] : []
    content {
      error_code            = custom_error_response.value
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 0
    }
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn # must be in us-east-1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    bucket          = var.log_bucket_name == null ? null : "${var.log_bucket_name}.s3.amazonaws.com"
    include_cookies = false
    prefix          = "cloudfront/${var.domain_name}/"
  }

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# ---------------- Route 53 ----------------
data "aws_route53_zone" "zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name = aws_cloudfront_distribution.this.domain_name
    # CloudFront's global hosted zone ID (constant):
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

resource "aws_cloudfront_function" "append_index_html" {
  name    = "${var.name_prefix}-site-append-index-html"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite pretty URLs to index.html for site"
  publish = true

  code = <<EOT
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith('/')) {
    request.uri += 'index.html';
  } else if (!uri.includes('.')) {
    request.uri += '/index.html';
  }
  return request;
}
EOT
}