#############################################
# App Runner custom domain for API 
#############################################

# 1) Find the hosted zone for your root domain
data "aws_route53_zone" "root" {
  name         = var.root_domain_name
  private_zone = false
}

resource "aws_apprunner_custom_domain_association" "api_prod" {
  service_arn = module.apprunner.service_arn
  domain_name = var.api_domain_name

  # Not strictly required here; cert is managed by App Runner with DNS validation
  # but having a validated ACM for the same name is useful elsewhere.
}

# Validation CNAMEs that App Runner returns
resource "aws_route53_record" "apprunner_validation" {
  for_each = {
    for rec in aws_apprunner_custom_domain_association.api_prod.certificate_validation_records :
    rec.name => {
      name  = rec.name
      type  = rec.type
      value = rec.value
    }
  }

  zone_id = data.aws_route53_zone.root.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.value]
}

# Main CNAME to the App Runner DNS target (once association exists)
resource "aws_route53_record" "apprunner_api" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.api_domain_name
  type    = "CNAME"
  ttl     = 60
  records = [aws_apprunner_custom_domain_association.api_prod.dns_target]

  depends_on = [aws_route53_record.apprunner_validation]
}

output "api_host_cname_target" {
  value       = aws_apprunner_custom_domain_association.api_prod.dns_target
  description = "API CNAME target (App Runner)"
}
