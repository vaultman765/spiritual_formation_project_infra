# Security group for the future App Runner VPC connector
resource "aws_security_group" "apprunner_connector" {
  name   = "${var.project}-${var.env}-apprunner-connector-sg"
  vpc_id = module.vpc.vpc_id
  tags = {
    Project = var.project
    Env     = var.env
    Role    = "AppRunnerConnector"
    Managed = "Terraform"
  }
}

# security-groups.tf (root)
resource "aws_security_group" "ecs_tasks" {
  name        = "spiritual-formation-staging-ecs-tasks-sg"
  description = "Managed by Terraform"
  vpc_id      = module.vpc.vpc_id
  tags        = { Project = var.project, Env = var.env, Managed = "Terraform" }

  # Safety: avoid accidental destroy
  lifecycle { prevent_destroy = true }
}

resource "aws_security_group_rule" "ecs_tasks_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_tasks.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound to VPC endpoints & S3"
}


