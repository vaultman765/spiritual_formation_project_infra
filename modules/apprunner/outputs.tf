# terraform-docs:begin:outputs
# Outputs:
# - service_arn: ARN of the App Runner service.
# - service_url: Default *.awsapprunner.com URL (null when disabled).
# - service_status: Current status (RUNNING/PAUSED/etc; null when disabled).
# terraform-docs:end:outputs

output "service_arn" {
  value       = var.enabled ? aws_apprunner_service.this[0].arn : null
  description = "ARN of the App Runner service."
}

output "service_url" {
  value       = var.enabled ? aws_apprunner_service.this[0].service_url : null
  description = "Default App Runner URL."
}

output "service_status" {
  value       = var.enabled ? aws_apprunner_service.this[0].status : null
  description = "Service status."
}
output "vpc_connector_arn" {
  value       = var.enabled ? aws_apprunner_vpc_connector.this[0].arn : null
  description = "ARN of the App Runner VPC connector."
}