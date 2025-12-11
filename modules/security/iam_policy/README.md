# IAM Policy Module

## Overview

This Terraform module creates an AWS IAM Policy. It allows for flexible configuration of the policy document, path, description, and tags, adhering to project best practices.

## Features

- **Custom Policy Creation**: Create customer-managed IAM policies with JSON policy documents.
- **Path Support**: Organize policies using IAM paths (default `/`).
- **Tagging**: Comprehensive support for resource tagging.

## Usage

### Basic Example

```hcl
module "s3_read_only" {
  source = "./modules/security/iam_policy"

  name        = "S3ReadOnlyAccess-Custom"
  description = "Provides read-only access to a specific S3 bucket"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::my-bucket",
          "arn:aws:s3:::my-bucket/*"
        ]
      }
    ]
  })

  tags = {
    Environment = "production"
    Team        = "data"
  }
}
```

### Example with `aws_iam_policy_document` Data Source

```hcl
data "aws_iam_policy_document" "ec2_manage" {
  statement {
    sid       = "AllowStopStart"
    effect    = "Allow"
    actions   = [
      "ec2:StartInstances",
      "ec2:StopInstances"
    ]
    resources = ["arn:aws:ec2:*:*:instance/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/Environment"
      values   = ["dev"]
    }
  }
}

module "ec2_dev_policy" {
  source = "./modules/security/iam_policy"

  name        = "EC2DevManagement"
  path        = "/dev-teams/"
  description = "Allows developers to start/stop dev instances"
  policy      = data.aws_iam_policy_document.ec2_manage.json

  tags = {
    Environment = "development"
    Role        = "developer"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.14.1 |
| aws | ~> 6.22.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the policy | `string` | n/a | yes |
| policy | The policy document. This is a JSON formatted string | `string` | n/a | yes |
| path | Path in which to create the policy | `string` | `"/"` | no |
| description | Description of the IAM policy | `string` | `"Managed by Terraform"` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ARN assigned by AWS to this policy |
| arn | The ARN assigned by AWS to this policy |
| name | The name of the policy |
| description | The description of the policy |
| path | The path of the policy |
| policy | The policy document |

## License

This module is maintained as part of the AWS infrastructure project.
