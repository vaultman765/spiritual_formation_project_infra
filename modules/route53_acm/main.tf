terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # We use an aliased provider in parent for us-east-1
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Create the hosted zone only if manage_zone = true
resource "aws_route53_zone" "hosted" {
  count = var.manage_zone ? 1 : 0
  name  = var.root_domain_name
}

# Otherwise, look up the existing zone
data "aws_route53_zone" "existing" {
  count        = var.manage_zone ? 0 : 1
  name         = var.root_domain_name
  private_zone = false
}

# Helper: zone_id
locals {
  zone_id = var.manage_zone ? aws_route53_zone.hosted[0].zone_id : data.aws_route53_zone.existing[0].zone_id
}

# ACM cert in us-east-1 (required for App Runner/CloudFront)
resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  validation_method         = "DNS"
  provider                  = aws.us_east_1

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# Publish validation records in Route 53
resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = local.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

# Complete validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}
