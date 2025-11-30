# VPC Module

This Terraform module creates an AWS Virtual Private Cloud (VPC) with optional features including Internet Gateway, IPv6 support, VPC Flow Logs, and IPAM pool integration.

## Features

- Creates a VPC with customizable CIDR block or IPAM pool allocation
- Optional Internet Gateway creation and attachment
- IPv6 support with Amazon-provided CIDR blocks
- VPC Flow Logs with CloudWatch Logs or S3 destination support
- Automatic IAM role creation for CloudWatch Logs flow logs
- KMS encryption support for CloudWatch Logs using AWS-managed keys
- Deletion protection for CloudWatch Log Groups
- DNS support and hostname configuration
- Instance tenancy options (default or dedicated)
- Flexible tagging for all resources
</text>

<old_text line=62>
### VPC with Flow Logs to CloudWatch

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  # Enable Flow Logs
  enable_flow_logs              = true
  flow_logs_destination_type    = "cloud-watch-logs"
  flow_logs_traffic_type        = "ALL"
  flow_logs_retention_in_days   = 30

  tags = {
    Environment = "production"
  }
}
```

## Usage

### Basic VPC with Static CIDR

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### VPC with Internet Gateway

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  create_igw = true

  igw_tags = {
    Purpose = "Public Internet Access"
  }

  tags = {
    Environment = "production"
  }
}
```

### VPC with Flow Logs to CloudWatch

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  # Enable Flow Logs
  enable_flow_logs              = true
  flow_logs_destination_type    = "cloud-watch-logs"
  flow_logs_traffic_type        = "ALL"
  flow_logs_retention_in_days   = 30

  tags = {
    Environment = "production"
  }
}
```

### VPC with Flow Logs - Enhanced Security (KMS Encryption + Deletion Protection)

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-secure-vpc"
  cidr_block = "10.0.0.0/16"

  # Enable Flow Logs with enhanced security features
  enable_flow_logs                    = true
  flow_logs_destination_type          = "cloud-watch-logs"
  flow_logs_traffic_type              = "ALL"
  flow_logs_retention_in_days         = 90
  
  # Enable KMS encryption using AWS-managed key (default: true)
  flow_logs_enable_kms_encryption     = true
  
  # Enable deletion protection to prevent accidental deletion
  flow_logs_log_group_skip_destroy    = true

  tags = {
    Environment = "production"
    Security    = "high"
  }
}
```

### VPC with Flow Logs to S3

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  # Enable Flow Logs to S3
  enable_flow_logs           = true
  flow_logs_destination_type = "s3"
  flow_logs_s3_bucket_arn    = "arn:aws:s3:::my-flow-logs-bucket"
  flow_logs_s3_key_prefix    = "vpc-logs/"
  flow_logs_traffic_type     = "ALL"

  tags = {
    Environment = "production"
  }
}
```

### VPC with IPAM Pool

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name                 = "my-vpc"
  ipv4_ipam_pool_id    = "ipam-pool-0a1b2c3d4e5f6g7h8"
  ipv4_netmask_length  = 16

  create_igw = true

  tags = {
    Environment = "production"
  }
}
```

### VPC with IPv6 Support

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-vpc"
  cidr_block = "10.0.0.0/16"

  enable_ipv6 = true
  create_igw  = true

  tags = {
    Environment = "production"
  }
}
```

### Complete Example with All Features

```hcl
module "vpc" {
  source = "./modules/networking/vpc"

  name       = "my-complete-vpc"
  cidr_block = "10.0.0.0/16"

  # DNS Configuration
  enable_dns_support   = true
  enable_dns_hostnames = true

  # IPv6 Support
  enable_ipv6 = true

  # Internet Gateway
  create_igw = true
  igw_tags = {
    Purpose = "Public Access"
  }

  # VPC Flow Logs
  enable_flow_logs                    = true
  flow_logs_destination_type          = "cloud-watch-logs"
  flow_logs_traffic_type              = "ALL"
  flow_logs_retention_in_days         = 30
  flow_logs_max_aggregation_interval  = 600

  tags = {
    Environment = "production"
    Project     = "my-project"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.12.1 |
| aws | ~> 6.22.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the VPC (used in Name tag) | `string` | n/a | yes |
| cidr_block | CIDR block for the VPC (used when not using IPAM) | `string` | `null` | no* |
| ipv4_ipam_pool_id | ID of the IPv4 IPAM pool from which to allocate a CIDR (optional) | `string` | `null` | no* |
| ipv4_netmask_length | Netmask length used when allocating from the IPv4 IPAM pool (required if ipv4_ipam_pool_id is set) | `number` | `null` | conditional** |
| enable_dns_support | Enable DNS support in the VPC | `bool` | `true` | no |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_ipv6 | Whether to assign an IPv6 CIDR block to the VPC | `bool` | `false` | no |
| instance_tenancy | A tenancy option for instances launched into the VPC (default or dedicated) | `string` | `"default"` | no |
| create_igw | Whether to create and attach an Internet Gateway to this VPC | `bool` | `false` | no |
| igw_tags | Additional tags to apply specifically to the Internet Gateway | `map(string)` | `{}` | no |
| enable_flow_logs | Whether to enable VPC Flow Logs | `bool` | `false` | no |
| flow_logs_destination_type | Destination type for VPC Flow Logs: cloud-watch-logs or s3 | `string` | `"cloud-watch-logs"` | no |
| flow_logs_traffic_type | The type of traffic to log: ACCEPT, REJECT, or ALL | `string` | `"ALL"` | no |
| flow_logs_log_group_name | Custom CloudWatch Log Group name for VPC Flow Logs (optional). If null, a default name is used. | `string` | `null` | no |
| flow_logs_retention_in_days | Retention in days for Flow Logs CloudWatch Log Group | `number` | `30` | no |
| flow_logs_log_group_skip_destroy | Enable deletion protection for Flow Logs CloudWatch Log Group (skip_destroy) | `bool` | `false` | no |
| flow_logs_enable_kms_encryption | Enable KMS encryption for Flow Logs CloudWatch Log Group using AWS-managed key (aws/logs) | `bool` | `true` | no |
| flow_logs_s3_bucket_arn | S3 bucket ARN for VPC Flow Logs (required if destination type is s3) | `string` | `null` | conditional*** |
| flow_logs_s3_key_prefix | Prefix for S3 objects when destination type is s3 | `string` | `"vpc-flow-logs/"` | no |
| flow_logs_max_aggregation_interval | Maximum interval of time during which a flow is captured and aggregated into one flow log record (60 or 600 seconds) | `number` | `600` | no |
| tags | Additional tags to apply to all resources created by this module | `map(string)` | `{}` | no |

**\*Note:** You must provide either `cidr_block` OR `ipv4_ipam_pool_id`, but not both.

**\*\*Note:** When `ipv4_ipam_pool_id` is set, `ipv4_netmask_length` must also be set.

**\*\*\*Note:** When `flow_logs_destination_type` is `"s3"`, `flow_logs_s3_bucket_arn` must be set.

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| vpc_arn | ARN of the VPC |
| vpc_cidr_block | CIDR block of the VPC |
| vpc_ipv6_cidr_block | IPv6 CIDR block of the VPC (if enabled) |
| default_security_group_id | Default security group ID of the VPC |
| igw_id | ID of the Internet Gateway (null if not created) |
| flow_logs_id | ID of the VPC Flow Log (null if not enabled) |
| flow_logs_log_group_name | CloudWatch Log Group name used for VPC Flow Logs (null if not using CloudWatch) |
| flow_logs_s3_bucket_arn | S3 bucket ARN used for VPC Flow Logs (null if not using S3) |

## Resources Created

This module creates the following AWS resources:

- `aws_vpc.this` - The VPC itself
- `aws_internet_gateway.this` - Internet Gateway (if `create_igw = true`)
- `aws_flow_log.this` - VPC Flow Log (if `enable_flow_logs = true`)
- `aws_cloudwatch_log_group.flow_logs` - CloudWatch Log Group for Flow Logs (if using CloudWatch destination)
- `aws_iam_role.flow_logs` - IAM role for Flow Logs to write to CloudWatch (if using CloudWatch destination)
- `aws_iam_role_policy.flow_logs` - IAM policy for Flow Logs (if using CloudWatch destination)
- `data.aws_kms_key.cloudwatch_logs` - AWS-managed KMS key for CloudWatch Logs encryption (if encryption is enabled)

## VPC Flow Logs

VPC Flow Logs capture information about IP traffic going to and from network interfaces in your VPC. This module supports two destination types:

### CloudWatch Logs
When using CloudWatch Logs as the destination:
- A CloudWatch Log Group is automatically created
- An IAM role and policy are automatically created with the necessary permissions
- You can customize the log group name and retention period
- Default log group name format: `/aws/vpc/{vpc-name}-flow-logs`
- **KMS Encryption**: Enabled by default using AWS-managed key (`alias/aws/logs`) - no additional KMS key creation required
- **Deletion Protection**: Optional `skip_destroy` protection prevents accidental deletion of log groups

### S3
When using S3 as the destination:
- You must provide an existing S3 bucket ARN
- The bucket must have the appropriate bucket policy to allow VPC Flow Logs to write to it
- You can customize the S3 key prefix for organizing logs
- No IAM role is created (VPC Flow Logs uses a service-linked role for S3)

### Flow Logs Configuration Options

- **Traffic Type**: Choose to log `ACCEPT`, `REJECT`, or `ALL` traffic
- **Aggregation Interval**: Set to `60` seconds for detailed logs or `600` seconds (10 minutes) for less granular logs
- **Retention**: Configure CloudWatch log retention (only applies to CloudWatch destination)
- **KMS Encryption**: Automatically enabled using AWS-managed KMS key for CloudWatch Logs - can be disabled if needed
- **Deletion Protection**: Optionally enable `skip_destroy` to prevent accidental deletion of CloudWatch Log Groups

## Notes

- The module validates that you provide either `cidr_block` or `ipv4_ipam_pool_id`, preventing configuration errors
- When using IPAM pools, you must specify the `ipv4_netmask_length` parameter
- The Internet Gateway is only created when `create_igw = true`
- VPC Flow Logs are optional and controlled by the `enable_flow_logs` variable
- When using S3 as the Flow Logs destination, ensure your S3 bucket has the proper bucket policy
- IAM resources for Flow Logs are only created when using CloudWatch Logs destination
- KMS encryption for CloudWatch Logs uses the AWS-managed key (`alias/aws/logs`) by default - enabled automatically
- Deletion protection (`skip_destroy`) for CloudWatch Log Groups can be enabled to prevent accidental deletion
- All resources inherit tags from the `tags` variable, with specific resource tags taking precedence
- Instance tenancy can be set to "default" or "dedicated" based on your requirements

## Examples

### Multi-Environment Setup with Flow Logs

```hcl
# Development VPC
module "dev_vpc" {
  source = "./modules/networking/vpc"

  name       = "dev-vpc"
  cidr_block = "10.0.0.0/16"
  create_igw = true

  # Enable Flow Logs for monitoring
  enable_flow_logs            = true
  flow_logs_retention_in_days = 7  # Shorter retention for dev

  tags = {
    Environment = "development"
  }
}

# Production VPC with Dedicated Tenancy and Comprehensive Logging
module "prod_vpc" {
  source = "./modules/networking/vpc"

  name             = "prod-vpc"
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "dedicated"
  create_igw       = true
  enable_ipv6      = true

  # Production Flow Logs to CloudWatch with encryption and deletion protection
  enable_flow_logs                    = true
  flow_logs_destination_type          = "cloud-watch-logs"
  flow_logs_traffic_type              = "ALL"
  flow_logs_retention_in_days         = 365
  flow_logs_enable_kms_encryption     = true   # AWS-managed KMS encryption
  flow_logs_log_group_skip_destroy    = true   # Deletion protection

  tags = {
    Environment = "production"
    Compliance  = "PCI-DSS"
  }
}
```

### Monitoring Rejected Traffic Only

```hcl
module "security_vpc" {
  source = "./modules/networking/vpc"

  name       = "security-vpc"
  cidr_block = "192.168.0.0/16"

  # Monitor only rejected traffic for security analysis
  enable_flow_logs                    = true
  flow_logs_traffic_type              = "REJECT"
  flow_logs_max_aggregation_interval  = 60  # More granular logs
  flow_logs_retention_in_days         = 90
  flow_logs_enable_kms_encryption     = true   # Encrypted by default
  flow_logs_log_group_skip_destroy    = true   # Protect from deletion

  tags = {
    Environment = "production"
    Purpose     = "Security Monitoring"
  }
}
```

## License

This module is maintained as part of the internal infrastructure codebase.