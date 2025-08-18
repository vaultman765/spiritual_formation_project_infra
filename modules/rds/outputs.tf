output "db_endpoint" {
  value       = var.enabled ? aws_db_instance.this[0].address : null
  description = "DB endpoint hostname (null when disabled)."
}

output "db_port" {
  value       = var.enabled ? aws_db_instance.this[0].port : null
  description = "DB port."
}

output "db_name" {
  value       = var.enabled ? aws_db_instance.this[0].db_name : null
  description = "DB name."
}

output "db_username" {
  value       = var.enabled ? aws_db_instance.this[0].username : null
  description = "DB admin username."
}

output "rds_sg_id" {
  value       = var.enabled ? aws_security_group.rds[0].id : null
  description = "RDS security group id."
}

output "secret_arn" {
  value       = aws_secretsmanager_secret.db.arn
  description = "Secrets Manager secret ARN (null when disabled)."
}