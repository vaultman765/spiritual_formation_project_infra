###########################################################
# Route 53 records for staging.catholicmentalprayer.com
# and api.staging.catholicmentalprayer.com
###########################################################

# Use the existing apex hosted zone
data "aws_route53_zone" "catholic" {
  name         = var.root_domain_name
  private_zone = false
}
