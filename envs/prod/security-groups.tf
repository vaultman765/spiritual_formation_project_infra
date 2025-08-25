# App Runner VPC connector -> DB, endpoints, etc.
resource "aws_security_group" "apprunner_connector" {
  name        = "${var.name_prefix}-apprunner-connector-sg"
  description = "App Runner VPC Connector"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# TODO tighten - or pontentially don't need?
# Egress-any is fine for now (we can tighten later / or rely on endpoints)
resource "aws_vpc_security_group_egress_rule" "apprunner_all_egress" {
  security_group_id = aws_security_group.apprunner_connector.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress (can tighten later)"
}

# Shared SG for ECS tasks (egress-only; EventBridge target will attach this)
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "Managed by Terraform"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  # Safety: avoid accidental destroy
  lifecycle { prevent_destroy = true }
}

# TODO tighten
resource "aws_security_group_rule" "ecs_tasks_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_tasks.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound to VPC endpoints & S3"
}
