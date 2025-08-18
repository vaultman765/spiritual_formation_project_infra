locals {
  name       = "${var.project}-${var.env}-clientvpn"
  tags       = { Project = var.project, Env = var.env, Managed = "Terraform" }
  vpc_dns_ip = cidrhost(data.aws_vpc.this.cidr_block, 2)
}

resource "aws_cloudwatch_log_group" "cvpn" {
  count             = var.enable_connection_logs ? 1 : 0
  name              = "/aws/vpn/${local.name}"
  retention_in_days = 14
  tags              = local.tags
}

# SG attached to the VPN endpoint ENIs; we'll allow this SG in RDS inbound
resource "aws_security_group" "cvpn" {
  name        = "${local.name}-sg"
  description = "Client VPN endpoint SG"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = local.name
  server_certificate_arn = var.server_certificate_arn
  client_cidr_block      = var.client_cidr_block
  split_tunnel           = var.split_tunnel
  vpc_id                 = var.vpc_id
  security_group_ids     = [aws_security_group.cvpn.id]
  dns_servers            = [local.vpc_dns_ip]

  # Mutual TLS: use the same CA as the server cert
  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.server_certificate_arn
  }

  connection_log_options {
    enabled              = var.enable_connection_logs
    cloudwatch_log_group = try(aws_cloudwatch_log_group.cvpn[0].name, null)
  }

  tags = local.tags
}

# Associate to 2 private subnets (multi-AZ)
resource "aws_ec2_client_vpn_network_association" "a" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.private_subnet_ids[0]
}
resource "aws_ec2_client_vpn_network_association" "b" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.private_subnet_ids[1]
}

# Authorize access to the whole VPC CIDR (kept safe via SG on RDS)
data "aws_vpc" "this" { id = var.vpc_id }
resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = data.aws_vpc.this.cidr_block
  authorize_all_groups   = true
  description            = "Allow VPN clients to reach VPC"
}
