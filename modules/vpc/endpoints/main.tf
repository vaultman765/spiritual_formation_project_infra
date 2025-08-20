terraform {
  required_providers { aws = { source = "hashicorp/aws", version = ">= 5.0" } }
}

# Fetch VPC for CIDR resolution (for the "allow from VPC CIDR" option)
data "aws_vpc" "this" {
  id = var.vpc_id
}

locals {
  sg_name = var.security_group_name != "" ? var.security_group_name : (
    var.name_prefix != "" ? "${var.name_prefix}-vpce-sg" : "${var.project}-${var.env}-vpce-sg"
  )
}

resource "aws_security_group" "vpce" {
  name        = local.sg_name
  description = "Allow HTTPS to VPC endpoints"
  vpc_id      = var.vpc_id

  # Ingress from the whole VPC CIDR (matches your current file)
  dynamic "ingress" {
    for_each = var.allow_from_vpc_cidr ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.this.cidr_block]
    }
  }

  # Egress allow all (matches your current file)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Additional ingress from specific SGs (your explicit ecs_tasks rule)
resource "aws_security_group_rule" "vpce_ingress_from_tasks" {
  for_each                 = var.allowed_sg_ids
  type                     = "ingress"
  security_group_id        = aws_security_group.vpce.id
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "Allow HTTPS from tasks/services to endpoints"
}

# Interface endpoints
resource "aws_vpc_endpoint" "secretsmanager" {
  count               = var.enable_secretsmanager ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = var.tags
}

resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_ecr_api ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = var.tags
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_dkr ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = var.tags
}

resource "aws_vpc_endpoint" "logs" {
  count               = var.enable_logs ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags                = var.tags
}
