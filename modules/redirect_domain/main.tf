terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # CloudFront & ACM must run in us-east-1
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  # Helpful text and tagging
  comment = var.comment != "" ? var.comment : "Redirect: ${join(", ", var.from_domains)} -> ${var.to_domain}"
  tags = merge(
    {
      Project   = var.project
      Env       = var.env
      ManagedBy = "Terraform"
    },
    var.extra_tags
  )
}

# ---------------- ACM (us-east-1) ----------------
# One cert that covers ALL source hostnames (SANs)
resource "aws_acm_certificate" "cert" {
  provider                  = aws.us_east_1
  domain_name               = var.from_domains[0]
  validation_method         = "DNS"
  subject_alternative_names = length(var.from_domains) > 1 ? slice(var.from_domains, 1, length(var.from_domains)) : null

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

# Create DNS validation records in the provided hosted zone
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

# ---------------- CloudFront Function (viewer-request) ----------------
# 301 redirect to the target domain, preserving path + query string
resource "aws_cloudfront_function" "redirect" {
  provider = aws.us_east_1

  name    = "${var.name_prefix}-redirect"
  runtime = "cloudfront-js-2.0"
  publish = true
  comment = local.comment

  code = <<-JS
    function handler(event) {
      var req = event.request;
      var location = "https://${var.to_domain}" + req.uri;

      // preserve query string (CloudFront passes as a map)
      if (req.querystring && Object.keys(req.querystring).length > 0) {
        var qs = [];
        for (var k in req.querystring) {
          var q = req.querystring[k];
          // q is { value: "..." } or {}
          if (q && typeof q.value !== "undefined" && q.value !== null && q.value !== "") {
            qs.push(encodeURIComponent(k) + "=" + encodeURIComponent(q.value));
          } else {
            qs.push(encodeURIComponent(k));
          }
        }
        location += "?" + qs.join("&");
      }

      return {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: {
          "location":      { "value": location },
          "cache-control": { "value": "public, max-age=${var.browser_cache_seconds}" }
        }
      };
    }
  JS
}

# ---------------- CloudFront Distribution ----------------
# Uses a dummy HTTPS origin; the function returns immediately on viewer-request
resource "aws_cloudfront_distribution" "this" {
  provider = aws.us_east_1
  # checkov:skip=CKV_AWS_305 reason="Redirect-only distribution; default root object not applicable"
  # TODO (We’ll consider WAF/geo/origin-failover later or skip them intentionally.)

  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.comment
  aliases             = var.from_domains
  price_class         = var.price_class
  wait_for_deployment = true
  tags                = local.tags

  origin {
    domain_name = "example.com"
    origin_id   = "dummy-origin"
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  dynamic "logging_config" {
    for_each = var.log_bucket_name == null ? [] : [1]
    content {
      bucket          = "${var.log_bucket_name}.s3.amazonaws.com"
      include_cookies = false
      prefix          = "cloudfront/redirect/${var.name_prefix}/"
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    min_ttl                = 0
    default_ttl            = 300
    max_ttl                = 300

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    response_headers_policy_id = var.response_headers_policy_id
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# ---------------- Route53 Alias A records ----------------
resource "aws_route53_record" "alias" {
  for_each = toset(var.from_domains)

  zone_id = var.hosted_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront constant
    evaluate_target_health = false
  }
}
