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
}
