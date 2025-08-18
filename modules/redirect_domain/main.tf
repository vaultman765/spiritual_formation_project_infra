terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # We assume caller passes aws.us_east_1 for CF/ACM
      configuration_aliases = [aws.us_east_1]
    }
  }
}

locals {
  tags = {
    Project   = var.project
    Env       = var.env
    ManagedBy = "Terraform"
  }
}

# CloudFront Function: 301 to target_host, preserve path+query
resource "aws_cloudfront_function" "redirect" {
  name    = "${var.project}-${var.env}-redir"
  runtime = "cloudfront-js-2.0"
  comment = "Redirect ${join(", ", var.source_domains)} -> ${var.target_host}"

  code = <<-JS
    function handler(event) {
      var req = event.request;
      var location = "https://${var.target_host}" + req.uri;
      if (req.querystring && Object.keys(req.querystring).length > 0) {
        var qs = [];
        for (var k in req.querystring) {
          var v = req.querystring[k].value;
          if (v !== undefined && v !== null && v !== "") {
            qs.push(encodeURIComponent(k) + "=" + encodeURIComponent(v));
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
          "location":       { "value": location },
          "cache-control":  { "value": "public, max-age=300" }
        }
      };
    }
  JS
}

# Dummy origin (never hit; function returns at viewer-request)
resource "aws_cloudfront_distribution" "this" {
  provider = aws.us_east_1

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Redirect: ${join(", ", var.source_domains)} -> ${var.target_host}"
  aliases         = var.source_domains

  origin {
    domain_name = "example.com"
    origin_id   = "dummy-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "dummy-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 300
  }

  price_class = var.price_class

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn   # must be us-east-1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.tags
}

# Route53 A/ALIAS for each source domain -> this CF distribution
data "aws_route53_zone" "root" {
  # Note: the caller env will pass the default aws provider for the zone region/account
  name         = regex("\\.(.*)$", var.source_domains[0]) != null ? regex("\\.(.*)$", var.source_domains[0])[0] : var.source_domains[0]
  private_zone = false
}

resource "aws_route53_record" "alias" {
  for_each = toset(var.source_domains)

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.value
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront global zone id
    evaluate_target_health = false
  }
}
