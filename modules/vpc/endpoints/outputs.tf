output "sg_id" { value = aws_security_group.vpce.id }

output "secretsmanager_endpoint_id" { value = try(aws_vpc_endpoint.secretsmanager[0].id, null) }
output "ecr_api_endpoint_id" { value = try(aws_vpc_endpoint.ecr_api[0].id, null) }
output "ecr_dkr_endpoint_id" { value = try(aws_vpc_endpoint.ecr_dkr[0].id, null) }
output "logs_endpoint_id" { value = try(aws_vpc_endpoint.logs[0].id, null) }
