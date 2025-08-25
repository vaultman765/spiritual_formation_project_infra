# envs/prod/seo_verification.tf

# Combined verification codes for Google and Yandex. Bing used Googles verification 
resource "aws_route53_record" "domain_verification" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = "catholicmentalprayer.com"
  type    = "TXT"
  ttl     = 300
  records = concat(var.google_verification, var.yandex_verification)
}

