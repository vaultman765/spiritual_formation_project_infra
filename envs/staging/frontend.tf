###########################################################
# Staging Frontend via reusable module
# Domain: staging.catholicmentalprayer.com
###########################################################
module "frontend_staging" {
  source = "../../modules/cloudfront_site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  domain_name         = var.frontend_domain_name
  hosted_zone_name    = var.root_domain_name
  acm_certificate_arn = module.route53_acm_frontend_staging.certificate_arn

  # Optional overrides
  # bucket_name  = "staging-catholicmentalprayer-com-frontend" # uncomment if you want a fixed name
  price_class = "PriceClass_100"
  spa_mode    = true
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0
}

# terraform-docs:begin:outputs
# Outputs:
# - staging_frontend_bucket: S3 bucket for staging frontend assets.
# - staging_frontend_cf_domain: CloudFront domain for staging site.
# - staging_frontend_alias: Route53 A/ALIAS for staging host.
# terraform-docs:end:outputs
