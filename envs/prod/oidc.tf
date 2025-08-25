# Read OIDC provider ARN from staging state (adjust bucket/key/region to your backend)
data "terraform_remote_state" "staging" {
  backend = "s3"
  config = {
    bucket         = "tfstate-spiritual-formation"
    key            = "tfstate/staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tfstate-lock-spiritual-formation"
    encrypt        = true
  }
}

# GitHub OIDC role for prod builds (assume by Actions in your repo)
module "github_oidc_apprepo_build" {
  source            = "../../modules/iam/github_oidc_role"
  role_name         = "${var.name_prefix}-github-apprepo-build"
  oidc_provider_arn = data.terraform_remote_state.staging.outputs.github_oidc_provider_arn

  github_owner = var.github_owner
  github_repo  = var.github_repo
  github_refs  = var.github_refs
}

# Grant ECR push/pull on the prod repo + auth token
data "aws_iam_policy_document" "app_build_prod" {
  statement {
    sid       = "ECRLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid    = "ECRPushPull"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [module.ecr_backend.repo_arn]
  }
}

resource "aws_iam_policy" "app_build_prod" {
  name   = "${var.name_prefix}-app-build"
  policy = data.aws_iam_policy_document.app_build_prod.json
  tags   = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "app_build_prod_attach" {
  role       = module.github_oidc_apprepo_build.role_name
  policy_arn = aws_iam_policy.app_build_prod.arn
}

output "apprepo_build_role_arn" {
  value       = module.github_oidc_apprepo_build.role_arn
  description = "Use in GitHub Actions to push prod images."
}

# Allow GitHub Actions prod build role to trigger App Runner deployments
data "aws_iam_policy_document" "apprunner_ci_prod" {
  statement {
    sid       = "AppRunnerDeploy"
    effect    = "Allow"
    actions   = ["apprunner:StartDeployment", "apprunner:UpdateService", "apprunner:DescribeService"]
    resources = [module.apprunner.service_arn]
  }
  statement {
    sid       = "AppRunnerReadList"
    effect    = "Allow"
    actions   = ["apprunner:ListServices", "apprunner:ListOperations"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "apprunner_ci_prod" {
  name   = "sf-prod-apprunner-deploy"
  policy = data.aws_iam_policy_document.apprunner_ci_prod.json
  tags   = { Project = var.project, Env = var.env, Managed = "Terraform" }
}

resource "aws_iam_role_policy_attachment" "apprunner_ci_prod_attach" {
  role       = module.github_oidc_apprepo_build.role_name
  policy_arn = aws_iam_policy.apprunner_ci_prod.arn
}