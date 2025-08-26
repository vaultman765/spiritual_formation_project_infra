############################################################
# Secret rotation → Lambda → App Runner StartDeployment
############################################################

# Toggle if you ever want to disable this
variable "enable_secret_rotation_autodeploy" {
  type    = bool
  default = true
}

locals {
  lambda_name = "${var.name_prefix}-apprunner-redeploy"
  lambda_code = <<-EOT
import os, json, boto3

APP_RUNNER_ARN = os.environ["APP_RUNNER_ARN"]
client = boto3.client("apprunner")

def handler(event, context):
    # event is the rotation success CloudTrail event; we don't need to parse it
    try:
        resp = client.start_deployment(ServiceArn=APP_RUNNER_ARN)
        return {
            "statusCode": 200,
            "body": json.dumps({"operationId": resp.get("OperationId")})
        }
    except Exception as e:
        print(f"[ERROR] {e}")
        raise
EOT
}

# IAM trust for Lambda
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apprunner_redeploy" {
  count              = var.enable_secret_rotation_autodeploy ? 1 : 0
  name               = local.lambda_name
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# Minimal inline policy: logs + App Runner StartDeployment
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apprunner/${var.name_prefix}:*"]
  }

  statement {
    sid       = "AppRunnerDeploy"
    effect    = "Allow"
    actions   = ["apprunner:StartDeployment", "apprunner:DescribeService", "apprunner:ListOperations"]
    resources = [module.apprunner.service_arn]
  }
  statement {
    sid       = "SNSPublish"
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.lambda_dlq.arn]
  }
}

resource "aws_iam_role_policy" "apprunner_redeploy" {
  count  = var.enable_secret_rotation_autodeploy ? 1 : 0
  name   = "${local.lambda_name}-policy"
  role   = aws_iam_role.apprunner_redeploy[0].id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

# Package the lambda from inline source
data "archive_file" "apprunner_redeploy_zip" {
  type        = "zip"
  output_path = "${path.module}/apprunner_redeploy.zip"

  source {
    content  = local.lambda_code
    filename = "index.py"
  }
}

resource "aws_lambda_function" "apprunner_redeploy" {
  # checkov:skip=CKV_AWS_117
  # Justification: Lambda calls App Runner public API only; VPC adds cold starts and isn’t required.
  count                          = var.enable_secret_rotation_autodeploy ? 1 : 0
  function_name                  = local.lambda_name
  role                           = aws_iam_role.apprunner_redeploy[0].arn
  handler                        = "index.handler"
  runtime                        = "python3.12"
  filename                       = data.archive_file.apprunner_redeploy_zip.output_path
  source_code_hash               = data.archive_file.apprunner_redeploy_zip.output_base64sha256
  kms_key_arn                    = module.kms_logs.kms_key_arn
  # reserved_concurrent_executions = 2
  timeout                        = 30
  environment {
    variables = {
      APP_RUNNER_ARN = module.apprunner.service_arn
    }
  }
  dead_letter_config {
    target_arn = aws_sns_topic.lambda_dlq.arn
  }
  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_sns_topic" "lambda_dlq" {
  name              = "${var.name_prefix}-lambda-dlq"
  kms_master_key_id = module.kms_logs.kms_key_arn
}

############################################################
# EventBridge rule: Secrets Manager rotation succeeded
############################################################
# Match ONLY your RDS secret’s rotation success
resource "aws_cloudwatch_event_rule" "secret_rotation" {
  count       = var.enable_secret_rotation_autodeploy ? 1 : 0
  name        = "${var.name_prefix}-apprunner-secret-rotation"
  description = "On Secrets Manager RotationSucceeded, trigger App Runner deployment"

  event_pattern = jsonencode({
    "source" : ["aws.secretsmanager"],
    "detail-type" : [
      "AWS Service Event via CloudTrail",
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : ["secretsmanager.amazonaws.com"],
      "eventName" : ["RotationSucceeded"],
      "additionalEventData" : {
        "SecretId" : [var.rds_secret_arn]
      }
    }
  })
  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_cloudwatch_event_target" "apprunner_deploy" {
  count = var.enable_secret_rotation_autodeploy ? 1 : 0
  rule  = aws_cloudwatch_event_rule.secret_rotation[0].name
  arn   = aws_lambda_function.apprunner_redeploy[0].arn
}

# Allow EventBridge to invoke the Lambda
resource "aws_lambda_permission" "events_invoke_lambda" {
  count         = var.enable_secret_rotation_autodeploy ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.apprunner_redeploy[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.secret_rotation[0].arn
}
