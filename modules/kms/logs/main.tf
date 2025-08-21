data "aws_caller_identity" "this" {}
data "aws_region" "this" {}
locals {
  account_id = data.aws_caller_identity.this.account_id
  region = data.aws_region.this.name
  # Allow CW Logs to use the key for any log group in this account/region.
  # If you prefer to scope to a single LG later, we can tighten:
  #   arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/vpc/${var.name_prefix}/flow-logs
  cwlogs_context_arn = "arn:aws:logs:${local.region}:${local.account_id}:*"
  
  admin_statement = length(var.admin_principal_arns) > 0 ? [
    {
      Sid      = "AllowKeyAdmins"
      Effect   = "Allow"
      Principal = { AWS = var.admin_principal_arns }
      Action   = [
        "kms:Create*","kms:Describe*","kms:Enable*","kms:List*","kms:Put*",
        "kms:Update*","kms:Revoke*","kms:Disable*","kms:Get*","kms:Delete*",
        "kms:TagResource","kms:UntagResource","kms:ScheduleKeyDeletion","kms:CancelKeyDeletion"
      ]
      Resource = "*"
    }
  ] : []

  base_statements = [
    {
      Sid      = "AllowRootAccount"
      Effect   = "Allow"
      Principal = { AWS = "arn:aws:iam::${local.account_id}:root" }
      Action   = "kms:*"
      Resource = "*"
    },
    {
      Sid    = "AllowCloudWatchLogsUse"
      Effect = "Allow"
      Principal = { Service = "logs.${local.region}.amazonaws.com" }
      Action = [
        "kms:Encrypt","kms:Decrypt","kms:ReEncrypt*",
        "kms:GenerateDataKey*","kms:DescribeKey"
      ]
      Resource  = "*"
      Condition = {
        ArnEquals = { "kms:EncryptionContext:aws:logs:arn" = local.cwlogs_context_arn }
      }
    }
  ]

  key_policy = {
    Version   = "2012-10-17"
    Statement = concat(local.base_statements, local.admin_statement)
  }
}


resource "aws_kms_key" "logs" {
  description             = "${var.name_prefix} CloudWatch Logs KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = jsonencode(local.key_policy)
  tags                    = var.tags
}

resource "aws_kms_alias" "logs" {
  name          = "alias/${var.name_prefix}/logs"
  target_key_id = aws_kms_key.logs.id
}
