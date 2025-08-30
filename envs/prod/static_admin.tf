###########################################################
# CloudFront (OAC) → S3 private for Django admin static
# Host: static.staging.catholicmentalprayer.com
# Origin path: /django/static
###########################################################
module "static_admin_prod" {
  source = "../../modules/cloudfront_static"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region
  name_prefix = var.name_prefix

  bucket_name         = var.metadata_bucket
  origin_path         = ""
  domain_name         = "static.${var.root_domain_name}"
  hosted_zone_name    = var.root_domain_name
  acm_certificate_arn = module.route53_acm_static_prod.certificate_arn

  # Caching & TLS
  price_class = "PriceClass_100"
  default_ttl = 86400
  max_ttl     = 604800
  min_ttl     = 0

  # Attach security headers
  response_headers_policy_id = module.cf_policies.static_cors_policy_id

  # WAF
  web_acl_arn = aws_wafv2_web_acl.prod.arn

  # Geo Restrictions
  geo_restriction_type = "blacklist"
  geo_locations        = ["RU", "CN"]

  # Enable access logging
  log_bucket_name = module.logging.log_bucket_name

  # Stop ACM race conditions
  depends_on = [module.route53_acm_static_prod]
}
