locals {
  enabled = module.this.enabled
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.assumable_roles
  }
}

data "aws_iam_policy_document" "assume_role_with_mfa" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = var.assumable_roles
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = [var.mfa_age]
    }
  }
}


resource "aws_iam_policy" "this" {
  count       = local.enabled ? 1 : 0
  name        = module.this.id
  description = "Allows to assume role in another AWS account"
  policy      = var.mfa_enabled ? data.aws_iam_policy_document.assume_role_with_mfa.json : data.aws_iam_policy_document.assume_role.json

  tags = module.this.tags
}

resource "aws_iam_group" "this" {
  count = local.enabled ? 1 : 0
  name  = module.this.name
}

resource "aws_iam_group_policy_attachment" "this" {
  count      = local.enabled ? 1 : 0
  group      = aws_iam_group.this.0.id
  policy_arn = aws_iam_policy.this.0.id
}

resource "aws_iam_group_membership" "this" {
  count = local.enabled && length(var.group_users) > 0 ? 1 : 0

  group = aws_iam_group.this.0.id
  name  = var.name
  users = var.group_users
}
