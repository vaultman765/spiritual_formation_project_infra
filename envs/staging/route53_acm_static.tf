###########################################################
# ACM for static.staging.catholicmentalprayer.com (us-east-1)
###########################################################
module "route53_acm_static_staging" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  root_domain_name = var.root_domain_name
  domain_name      = "static.staging.catholicmentalprayer.com"
  manage_zone      = false
}

# terraform-docs:begin:outputs
# Outputs:
# - static_acm_arn: ACM ARN for static host.
# terraform-docs:end:outputs

