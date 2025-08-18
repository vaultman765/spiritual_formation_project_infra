output "endpoint_id" {
  description = "The Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "sg_id" {
  description = "Security group attached to the Client VPN endpoint ENIs"
  value       = aws_security_group.cvpn.id
}