data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Restrict to specific repo AND refs (branches/tags) you pass in.
    # Example values:
    #   - "repo:owner/repo:ref:refs/heads/main"
    #   - "repo:owner/repo:ref:refs/tags/v*"
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [for ref in var.github_refs : "repo:${var.github_owner}/${var.github_repo}:${ref}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name
  description        = "GitHub OIDC role for ${var.github_owner}/${var.github_repo}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
