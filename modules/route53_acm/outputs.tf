output "certificate_arn" {
  value = aws_acm_certificate.cert.arn
}

output "zone_id" {
  value = local.zone_id
}

output "name_servers" {
  value = var.manage_zone ? aws_route53_zone.hosted[0].name_servers : []
}
