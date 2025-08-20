# Least-Privilege IAM for GitHub OIDC Roles

Replace `AdministratorAccess` with scoped IAM policies.

---

## Metadata Sync (SPA → S3 + CF invalidation)

**Actions:**

- S3: `s3:PutObject`, `s3:AbortMultipartUpload`, `s3:ListBucket`
- CloudFront: `cloudfront:CreateInvalidation`

**Policy:**

```hcl
data "aws_iam_policy_document" "metadata_sync" {
  statement {
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload"]
    resources = ["arn:aws:s3:::${var.frontend_bucket}/*"]
  }
  statement {
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.frontend_bucket}"]
  }
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["arn:aws:cloudfront::${var.account_id}:distribution/${var.frontend_distribution_id}"]
  }
}
```

## App Build/Deploy (ECR + optional App Runner deploy)

**Actions:**

- ECR: `ecr:GetAuthorizationToken`, `ecr:PutImage`, `ecr:UploadLayerPart`, `ecr:Batch*`, `ecr:DescribeRepositories`

- Optional: `apprunner:StartDeployment`, `apprunner:Describe*`

Policy:

```hcl
data "aws_iam_policy_document" "app_build" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories"
    ]
    resources = ["arn:aws:ecr:${var.region}:${var.account_id}:repository/${var.repository_name}"]
  }
  statement {
    actions   = ["apprunner:StartDeployment", "apprunner:Describe*", "apprunner:List*"]
    resources = [var.apprunner_service_arn]
    condition { test = "Bool" variable = "var.allow_apprunner_deploy" values = ["true"] }
  }
}
```

## Read Secrets (App Runner execution, tasks)

**Actions:**

- `secretsmanager:GetSecretValue`

**Policy:**

```hcl
data "aws_iam_policy_document" "exec_read_secrets" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.db_secret_arn]
  }
}
```
