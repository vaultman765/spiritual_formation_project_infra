# VPC id (null when disabled)
output "vpc_id" {
  description = "VPC ID (null when disabled)"
  value       = var.enabled ? aws_vpc.this[0].id : null
}

# Public subnets ([] when disabled)
output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = var.enabled ? values(aws_subnet.public)[*].id : []
}

# Private subnets ([] when disabled)
output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = var.enabled ? values(aws_subnet.private)[*].id : []
}

# Public route table id (null when disabled)
output "public_route_table_id" {
  description = "Public route table ID"
  value       = var.enabled ? aws_route_table.public[0].id : null
}

# Private route table ids ([] when disabled)
output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = var.enabled ? values(aws_route_table.private)[*].id : []
}
