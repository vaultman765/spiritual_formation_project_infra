terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  # CloudFront → S3 via Origin Access Control (OAC), keep S3 fully private
  s3_arn = "arn:aws:s3:::${var.bucket_name}"
}

# ---------------- OAC (Origin Access Control) ----------------
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac-${var.domain_name}"
  description                       = "OAC for ${var.domain_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ---------------- CloudFront distribution ----------------
resource "aws_cloudfront_distribution" "static" {
  # checkov:skip=CKV2_AWS_47 reason="Log4j protection implemented via AWSManagedRulesKnownBadInputsRuleSet with Log4JRCE rule_action_override and AWSManagedRulesAnonymousIpList"
  provider = aws.us_east_1

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Static assets for ${var.domain_name}"

  aliases = [var.domain_name]

  web_acl_id = var.web_acl_arn

  origin {
    domain_name              = "${var.bucket_name}.s3.${var.region}.amazonaws.com"
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id

    # Optional path within the bucket, e.g. /django/static
    origin_path = var.origin_path
  }

  default_cache_behavior {
    target_origin_id       = "s3-${var.bucket_name}"
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

    response_headers_policy_id = aws_cloudfront_response_headers_policy.static_embed.id
  }
  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_locations
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  default_root_object = ""

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

data "aws_caller_identity" "this" {}

# ---------------- Route 53 A/ALIAS → CloudFront ----------------
data "aws_route53_zone" "zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

resource "aws_route53_record" "alias" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    # CloudFront’s global hosted zone ID is constant:
    zone_id                = "Z2FDTNDATAQYW2"
    name                   = aws_cloudfront_distribution.static.domain_name
    evaluate_target_health = false
  }
}

# ---------------- Response Headers Policy for Static Embed ----------------
resource "aws_cloudfront_response_headers_policy" "static_embed" {
  name = "sf-${var.env}-static-embed-policy"

  security_headers_config {
    frame_options {
      frame_option = "SAMEORIGIN" # instead of DENY
      override     = true
    }

    content_security_policy {
      content_security_policy = "frame-ancestors 'self';"
      override                = true
    }
  }

  custom_headers_config {
    items {
      header   = "Content-Disposition"
      value    = "inline"
      override = true
    }
  }
}

# ---------------- CloudFront Function: Append index.html ----------------
resource "aws_cloudfront_function" "append_index_html" {
  name    = "${var.name_prefix}-append-index-html"
  runtime = "cloudfront-js-1.0"
  comment = "Rewrite pretty URLs to index.html"
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
