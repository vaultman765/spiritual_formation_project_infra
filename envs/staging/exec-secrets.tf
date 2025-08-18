locals {
  exec_secret_arns = [var.rds_secret_arn, var.django_secret_arn]
}

data "aws_iam_role" "import_execution" {
  name = "${var.project}-${var.env}-import-execution-role"
}

resource "aws_iam_policy" "exec_read_secrets" {
  name        = "${var.project}-${var.env}-import-exec-read-secrets"
  description = "Allow ECS execution role to read container-injected secrets"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement : [
      { Effect : "Allow", Action : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"], Resource : local.exec_secret_arns },
      { Effect : "Allow", Action : ["kms:Decrypt"], Resource : "*",
      Condition : { StringEquals : { "kms:ViaService" : "secretsmanager.${var.region}.amazonaws.com" } } }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "exec_read_secrets" {
  role       = data.aws_iam_role.import_execution.name
  policy_arn = aws_iam_policy.exec_read_secrets.arn
}