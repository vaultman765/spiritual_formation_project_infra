resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-bot-prerender-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  provider         = aws.us_east_1
  function_name    = "${var.name_prefix}-bot-prerender"
  role             = aws_iam_role.this.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  publish          = true

  lifecycle {
    create_before_destroy = true
  }
}

data "local_file" "bot_code" {
  filename = "${path.module}/code/index.js"
}

locals {
  bot_code = replace(
    replace(data.local_file.bot_code.content, "__SITE_ORIGIN__", var.site_origin),
    "__API_BASE__", var.api_base
  )
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/bot.zip"

  source {
    content  = local.bot_code
    filename = "index.js"
  }
}
