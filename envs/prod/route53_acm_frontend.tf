###########################################################
# ACM certificate for staging.catholicmentalprayer.com
# Required for CloudFront (must be in us-east-1)
###########################################################

module "route53_acm_frontend_prod" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  # Root public zone already exists; we only want a cert
  manage_zone      = false
  root_domain_name = var.root_domain_name

  # The SPA host
  domain_name               = var.frontend_domain_name
  subject_alternative_names = []
}
