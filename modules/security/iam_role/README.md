# IAM Role Module

## Overview

This Terraform module creates an AWS IAM Role. It allows for creating roles with custom trust policies, attaching multiple managed/custom policies, and optionally creating an instance profile for EC2 usage.

## Features

- **IAM Role Creation**: Configurable trust policy, path, and description.
- **Policy Attachment**: Attach multiple IAM policies (managed or custom) via ARNs.
- **Instance Profile**: Optional creation of an instance profile for EC2.
- **Validation**: Built-in validation for names, JSON policies, and session duration.

## Usage

### Basic Role for EC2 (Trusting `ec2.amazonaws.com`)

```hcl
module "app_role" {
  source = "./modules/security/iam_role"

  name = "app-server-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::123456789012:policy/MyCustomPolicy"
  ]

  create_instance_profile = true

  tags = {
    Environment = "production"
    Service     = "app"
  }
}
```

### Role for Cross-Account Access

```hcl
module "cross_account_role" {
  source = "./modules/security/iam_role"

  name = "cross-account-admin"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::987654321098:root"
        }
      }
    ]
  })

  policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  max_session_duration = 43200 # 12 hours

  tags = {
    Type = "CrossAccount"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.14.1 |
| aws | ~> 6.27.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the IAM role | `string` | n/a | yes |
| assume_role_policy | The policy that grants an entity permission to assume the role (JSON string) | `string` | n/a | yes |
| policy_arns | List of ARNs of IAM policies to attach to the IAM role | `list(string)` | `[]` | no |
| description | Description of the IAM role | `string` | `"Managed by Terraform"` | no |
| create_instance_profile | Whether to create an instance profile for this role | `bool` | `false` | no |
| path | Path to the IAM role | `string` | `"/"` | no |
| force_detach_policies | Whether to force detaching any policies the role has before destroying it | `bool` | `false` | no |
| max_session_duration | Maximum session duration (in seconds) | `number` | `3600` | no |
| permissions_boundary | ARN of the policy that is used to set the permissions boundary | `string` | `null` | no |
| tags | A map of tags to assign to the resource | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_name | The name of the IAM role |
| role_id | The ID of the IAM role |
| role_arn | The ARN of the IAM role |
| role_unique_id | The stable and unique string identifying the role |
| instance_profile_name | The name of the instance profile (if created) |
| instance_profile_arn | The ARN of the instance profile (if created) |
| instance_profile_id | The ID of the instance profile (if created) |

## License

This module is maintained as part of the AWS infrastructure project.
