# ---------------------------------------------------------------------------------------------------------------------
# Helper Data Sources and Locals
# Retrieves current AWS account and region information, and defines a local variable for the KMS key ARN.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  # Determine the KMS key ARN to use: either a newly created one or an existing one provided by the user.
  kms_key_arn = var.create_kms_key ? aws_kms_key.this[0].arn : var.kms_key_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# KMS Key and Alias
# Manages the AWS KMS Key for EKS secrets encryption and its associated alias.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_kms_key" "this" {
  count = var.create_kms_key ? 1 : 0

  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy[0].json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.this[0].key_id
}

# ---------------------------------------------------------------------------------------------------------------------
# KMS Key Policy Document
# Defines the IAM policy for the KMS Key, granting necessary permissions for EKS and other AWS services.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "kms_key_policy" {
  count = var.create_kms_key ? 1 : 0

  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = length(var.kms_key_administrators) > 0 ? [1] : []

    content {
      sid    = "KeyAdministrators"
      effect = "Allow"
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion"
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.kms_key_administrators
      }
    }
  }

  statement {
    sid    = "Allow service-linked role use of the CMK"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com",
        "autoscaling.amazonaws.com",
        "logs.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
}
