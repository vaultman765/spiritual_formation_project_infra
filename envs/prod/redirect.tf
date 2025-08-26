module "redirect_mwc_prod" {
  source = "../../modules/redirect_domain"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project        = var.project
  env            = var.env
  name_prefix    = "${var.name_prefix}-redirect"
  hosted_zone_id = var.redirect_hosted_zone_id

  from_domains = var.mwc_sources
  to_domain    = var.frontend_domain_name

  response_headers_policy_id = module.cf_policies.security_headers_policy_id
  log_bucket_name            = module.logging.log_bucket_name

  web_acl_arn = aws_wafv2_web_acl.prod.arn

  # Keep it open to all countries but satisfy Checkov
  geo_restriction_type = "none"
  geo_locations        = [] # Empty list means no countries are blocked
}
