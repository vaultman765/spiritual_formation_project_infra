###########################################################
# ACM certificate for staging.catholicmentalprayer.com
# Required for CloudFront (must be in us-east-1)
###########################################################

module "route53_acm_frontend_staging" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  root_domain_name = var.root_domain_name
  domain_name      = var.frontend_domain_name
  manage_zone      = false # reuse existing apex zone
}

# terraform-docs:begin:outputs
# Outputs:
# - acm_certificate_arn: ARN of the ACM cert for staging frontend.
# terraform-docs:end:outputs
