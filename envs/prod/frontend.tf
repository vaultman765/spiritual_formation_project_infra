###########################################################
# Frontend via reusable module
# Domain: www.catholicmentalprayer.com
###########################################################
module "frontend_site_prod" {
  source = "../../modules/cloudfront_site"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  # Domain & cert
  domain_name         = var.frontend_domain_name
  hosted_zone_name    = var.root_domain_name
  acm_certificate_arn = module.route53_acm_frontend_prod.certificate_arn

  # Reuse your logging bucket
  log_bucket_name = module.logging.log_bucket_name

  # Cache & behavior
  price_class = "PriceClass_100"
  spa_mode    = true
  default_ttl = 3600
  max_ttl     = 86400
  min_ttl     = 0

  # Attach the response headers policy you created earlier
  response_headers_policy_id = module.cf_policies.security_headers_policy_id

  # WAF
  web_acl_arn = aws_wafv2_web_acl.prod.arn
}
