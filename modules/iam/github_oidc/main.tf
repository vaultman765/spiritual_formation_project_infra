locals {
  name = "${var.project}-${var.env}-github-oidc-infra"
}

# GitHub OIDC identity provider (one per account)
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # Includes the current GitHub IdP root CA and the older one for safety
  thumbprint_list = [
    "a031c46782e6e6c662c2c87c76da9aa62ccabd8e", # GitHub Actions (current)
    "6938fd4d98bab03faadb97b34396831e3780aea1"  # legacy DigiCert
  ]
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "GitHubOIDCAssumeRole"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "infra" {
  name               = local.name
  description        = "Terraform role for ${var.github_owner}/${var.github_repo}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# TODO: Temporary: full admin while we bootstrap infra (we'll replace with least-priv later)
resource "aws_iam_role_policy_attachment" "admin" {
  count      = var.attach_admin_policy ? 1 : 0
  role       = aws_iam_role.infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
