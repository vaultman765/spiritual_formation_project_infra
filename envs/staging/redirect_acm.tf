module "mwc_redirect_acm" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  root_domain_name          = var.redirect_root_domain_name
  domain_name               = var.mwc_sources[0]
  subject_alternative_names = slice(var.mwc_sources, 1, length(var.mwc_sources))

  manage_zone = false
}
