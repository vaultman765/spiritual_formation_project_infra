# App Runner VPC connector -> DB, endpoints, etc.
resource "aws_security_group" "apprunner_connector" {
  name        = "${var.name_prefix}-apprunner-connector-sg"
  description = "App Runner VPC Connector"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# ECS tasks -> endpoints, DB, etc.
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "ECS task traffic"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# Egress-any is fine for now (we can tighten later / or rely on endpoints)
resource "aws_vpc_security_group_egress_rule" "apprunner_all_egress" {
  security_group_id = aws_security_group.apprunner_connector.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress (can tighten later)" # TODO tighten
}
resource "aws_vpc_security_group_egress_rule" "ecs_all_egress" {
  security_group_id = aws_security_group.ecs_tasks.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress (can tighten later)" # TODO tighten
}
