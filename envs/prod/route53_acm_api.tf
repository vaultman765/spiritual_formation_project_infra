module "route53_acm_api_prod" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  root_domain_name          = var.root_domain_name
  domain_name               = var.api_domain_name
  manage_zone               = false
  subject_alternative_names = []
}