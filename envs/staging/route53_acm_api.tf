###########################################################
# ACM certificate for api.staging.catholicmentalprayer.com
# Used by App Runner custom domain for the staging API.
# Must be in us-east-1 for compatibility with App Runner.
###########################################################

module "route53_acm_api_staging" {
  source = "../../modules/route53_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project = var.project
  env     = var.env
  region  = var.region

  root_domain_name = var.root_domain_name
  domain_name      = var.api_domain_name
  manage_zone      = false # reuse existing apex zone
}

# terraform-docs:begin:outputs
# Outputs:
# - acm_certificate_arn: ARN of the ACM cert for the staging API domain.
# terraform-docs:end:outputs
