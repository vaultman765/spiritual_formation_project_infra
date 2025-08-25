# Security group for rotation lambda -> DB
resource "aws_security_group" "sm_rotation" {
  name        = "${var.name_prefix}-sm-rotation"
  description = "Secrets Manager rotation function egress within VPC"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

# Allow Secrets Manager rotation Lambda -> Postgres
resource "aws_vpc_security_group_ingress_rule" "rds_from_rotation" {
  security_group_id            = module.rds.rds_sg_id    # your DB SG
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_security_group.sm_rotation.id
  description                  = "Postgres from SM rotation Lambda"
}

# Trust for Lambda
data "aws_iam_policy_document" "rot_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sm_rotation" {
  name               = "${var.name_prefix}-sm-rotation"
  assume_role_policy = data.aws_iam_policy_document.rot_trust.json
}

resource "aws_iam_role_policy_attachment" "sm_rotation_basic" {
  role       = aws_iam_role.sm_rotation.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to work with this secret (+ describe DB)
data "aws_iam_policy_document" "sm_rotation_inline" {
  statement {
    actions   = ["secretsmanager:GetSecretValue","secretsmanager:PutSecretValue","secretsmanager:DescribeSecret","secretsmanager:UpdateSecretVersionStage"]
    resources = [var.rds_secret_arn]
  }
  statement {
    actions   = ["rds:DescribeDBInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sm_rotation_inline" {
  name   = "${var.name_prefix}-sm-rotation-inline"
  policy = data.aws_iam_policy_document.sm_rotation_inline.json
}

resource "aws_iam_role_policy_attachment" "sm_rotation_inline_attach" {
  role       = aws_iam_role.sm_rotation.name
  policy_arn = aws_iam_policy.sm_rotation_inline.arn
}

data "aws_vpc_endpoint" "secretsmanager" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.secretsmanager"
}

# Deploy AWS's official **PostgreSQL Single User** rotation function from SAR
resource "aws_serverlessapplicationrepository_cloudformation_stack" "pg_single_user" {
  name           = "${var.name_prefix}-pg-rotation"
  application_id = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSPostgreSQLRotationSingleUser"
  capabilities   = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

  # Only these are needed; the Lambda will read username/host/port/dbname from the secret at runtime
  parameters = {
    functionName        = "${var.name_prefix}-pg-rotation"
    vpcSubnetIds        = join(",", module.vpc.private_subnet_ids)
    vpcSecurityGroupIds = aws_security_group.sm_rotation.id
    endpoint            = "https://${data.aws_vpc_endpoint.secretsmanager.dns_entry[0].dns_name}"
  }
}

# Wire rotation to your existing secret (every 30 days)
resource "aws_secretsmanager_secret_rotation" "db" {
  secret_id           = var.rds_secret_arn
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.pg_single_user.outputs["RotationLambdaARN"]

  rotation_rules { automatically_after_days = 30 }
  depends_on = [aws_serverlessapplicationrepository_cloudformation_stack.pg_single_user]
}

output "rotation_stack_outputs" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.pg_single_user.outputs
}