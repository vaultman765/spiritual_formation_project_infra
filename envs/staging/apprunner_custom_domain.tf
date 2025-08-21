#############################################
# App Runner custom domain for API (staging)
#############################################

# 1) Find the hosted zone for your root domain
data "aws_route53_zone" "root" {
  name         = var.root_domain_name
  private_zone = false
}

# 2) Associate the subdomain with your App Runner service
#    App Runner will return:
#      - certificate_validation_records: CNAMEs you must publish
#      - dns_target: the final CNAME target for your API hostname
resource "aws_apprunner_custom_domain_association" "api_staging" {
  count       = var.staging_infra_enabled ? 1 : 0
  domain_name = var.api_domain_name
  service_arn = module.apprunner.service_arn
}

# 3) Publish the validation CNAMEs that App Runner requires
# NOTE: This resource will fail on the first apply because
# aws_apprunner_custom_domain_association.api_staging.certificate_validation_records
# is not known until after the association is created.
# Solution: run `terraform apply -target=aws_apprunner_custom_domain_association.api_staging`
# then run `terraform apply` again.
resource "aws_route53_record" "apprunner_validation" {
  for_each = var.staging_infra_enabled ? {
    for rec in aws_apprunner_custom_domain_association.api_staging[0].certificate_validation_records :
    rec.name => {
      name  = rec.name
      type  = rec.type
      value = rec.value
    }
  } : {}

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

# 4) Publish the final CNAME so clients resolve your API hostname to App Runner
resource "aws_route53_record" "apprunner_api_cname" {
  count   = var.staging_infra_enabled ? 1 : 0
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.api_domain_name
  type    = "CNAME"
  ttl     = 60
  records = [aws_apprunner_custom_domain_association.api_staging[0].dns_target]
}
