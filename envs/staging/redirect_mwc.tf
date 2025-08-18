module "redirect_mwc" {
  source = "../../modules/redirect_domain"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project             = var.project
  env                 = var.env
  source_domains      = var.mwc_sources
  target_host         = var.frontend_domain_name
  acm_certificate_arn = module.mwc_redirect_acm.certificate_arn
}
