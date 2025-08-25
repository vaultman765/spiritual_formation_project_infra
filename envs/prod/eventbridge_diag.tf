resource "aws_cloudwatch_log_group" "evb_diag" {
  name              = "/eventbridge/diag"
  retention_in_days = 7
  tags              = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# Very broad: any Secrets Manager event
resource "aws_cloudwatch_event_rule" "diag_sm" {
  name        = "${var.name_prefix}-eb-diag-secrets"
  description = "Mirror all Secrets Manager events into CW Logs for debugging"
  event_pattern = jsonencode({
    "source": ["aws.secretsmanager"]
  })
  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_cloudwatch_event_target" "diag_sm_to_logs" {
  rule = aws_cloudwatch_event_rule.diag_sm.name
  arn  = aws_cloudwatch_log_group.evb_diag.arn
}
