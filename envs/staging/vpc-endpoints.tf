data "aws_vpc" "this" { id = module.vpc.vpc_id }

# Collect route tables for private subnets (for S3 gateway)
data "aws_route_table" "private" {
  for_each  = toset(module.vpc.private_subnet_ids)
  subnet_id = each.value
}

locals {
  private_rt_ids = toset([for rt in data.aws_route_table.private : rt.id])
  vpce_tags      = { Project = var.project, Env = var.env, Managed = "Terraform", Purpose = "VpcEndpoints" }
}

# SG for Interface Endpoints (allow 443 from VPC)
resource "aws_security_group" "vpce" {
  name        = "${var.project}-${var.env}-vpce-sg"
  description = "Allow HTTPS to VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.vpce_tags
}

resource "aws_security_group_rule" "vpce_ingress_from_tasks" {
  type                     = "ingress"
  security_group_id        = aws_security_group.vpce.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_tasks.id
  description              = "Allow HTTPS from ECS tasks to endpoints"
}

# Interface endpoints
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = local.vpce_tags
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = local.vpce_tags
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = local.vpce_tags
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = local.vpce_tags
}
