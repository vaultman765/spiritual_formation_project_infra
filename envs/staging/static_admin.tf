###########################################################
# CloudFront (OAC) → S3 private for Django admin static
# Host: static.staging.catholicmentalprayer.com
# Origin path: /django/static
###########################################################
module "static_admin_staging" {
  source = "../../modules/cloudfront_static"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  bucket_name         = var.metadata_bucket
  origin_path         = ""
  domain_name         = "static.staging.${var.root_domain_name}" # TODO check this to see why static not pulling in apprunner
  hosted_zone_name    = var.root_domain_name
  acm_certificate_arn = module.route53_acm_static_staging.certificate_arn

  price_class = "PriceClass_100"
  default_ttl = 86400
  max_ttl     = 604800
  min_ttl     = 0
}

# terraform-docs:begin:outputs
# Outputs:
# - static_admin_cf_domain: CF domain for static host.
# - static_admin_alias: R53 alias record FQDN for static host.
# - static_admin_distribution_id: CF distribution ID (for invalidations).
# terraform-docs:end:outputs

