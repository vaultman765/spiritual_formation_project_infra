###########################################################
# ACM for static.staging.catholicmentalprayer.com (us-east-1)
###########################################################
module "route53_acm_static_prod" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project                   = var.project
  env                       = var.env
  region                    = var.region
  domain_name               = "static.${var.root_domain_name}"
  subject_alternative_names = []
  manage_zone               = false
  root_domain_name          = var.root_domain_name
}
