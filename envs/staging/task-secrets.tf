# If you were using SSM instead, you’d add:
# variable "django_secret_param_arn" { type = string }

locals {
  task_secret_arns = compact([var.rds_secret_arn, var.django_secret_arn])
}

data "aws_iam_role" "import_task" {
  name = "${var.project}-${var.env}-import-task-role"
}

# Policy: allow code in the container to read secrets directly
resource "aws_iam_policy" "task_read_secrets" {
  name        = "${var.project}-${var.env}-import-task-read-secrets"
  description = "Allow ECS task role to read app secrets from Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "SecretsManagerRead",
        Effect : "Allow",
        Action : ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        Resource : local.task_secret_arns
      },
      # If your secret(s) are KMS-encrypted (they are), allow decrypt via SM
      {
        Sid : "KMSDecryptViaSM",
        Effect : "Allow",
        Action : ["kms:Decrypt"],
        Resource : "*",
        Condition : {
          StringEquals : {
            "kms:ViaService" : "secretsmanager.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_read_secrets" {
  role       = data.aws_iam_role.import_task.name
  policy_arn = aws_iam_policy.task_read_secrets.arn
}
