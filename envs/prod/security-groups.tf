# App Runner VPC connector -> DB, endpoints, etc.
resource "aws_security_group" "apprunner_connector" {
  # checkov:skip=CKV2_AWS_5
  # Justification: In use by aws_apprunner_vpc_connector (security_groups=[...]).
  name        = "${var.name_prefix}-apprunner-connector-sg"
  description = "App Runner VPC Connector"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_vpc_security_group_egress_rule" "apprunner_all_egress" {
  security_group_id = aws_security_group.apprunner_connector.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress (can tighten later)"
}

resource "aws_security_group" "ecs_tasks" {
  # checkov:skip=CKV2_AWS_5
  # Justification: Used at runtime by ECS Fargate tasks via EventBridge target network_configuration.
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "Managed by Terraform"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  # Safety: avoid accidental destroy
  lifecycle { prevent_destroy = true }
}

resource "aws_security_group_rule" "ecs_tasks_egress_all" {
  # checkov:skip=CKV_AWS_382: This is normal for egress‑only SGs
  type              = "egress"
  security_group_id = aws_security_group.ecs_tasks.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound to VPC endpoints & S3"
}
