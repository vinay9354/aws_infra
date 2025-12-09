# S3 Bucket Terraform Module

A reusable Terraform module for creating AWS S3 buckets with security best practices and advanced features.

## Overview

This module creates a fully configured S3 bucket with recommended security settings by default:

- **Private by default** - Public access blocked
- **Versioning** - Enabled by default
- **Server-side encryption** - SSE-S3 (AES256) or KMS
- **Public access blocking** - All public access blocked
- **Ownership controls** - BucketOwnerPreferred by default
- **Access logging** - Optional, with dedicated or existing logs bucket
- **Lifecycle rules** - Optional storage class transitions and expiration
- **Bucket policy** - Optional custom policies

---

## Features

- ✅ S3 bucket creation with customizable tags
- ✅ Ownership controls (BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced)
- ✅ Public access blocked by default
- ✅ ACL support (private, public-read, etc.)
- ✅ Versioning support (enabled by default)
- ✅ Server-side encryption:
  - `AES256` (SSE-S3) - default
  - `aws:kms` (with custom or AWS-managed KMS key)
  - Automatic KMS key creation option
- ✅ Access logging:
  - Create a dedicated logs bucket automatically
  - Use an existing logs bucket
  - Configurable log prefix
- ✅ Lifecycle rules:
  - Transition objects to different storage classes (STANDARD_IA, GLACIER, etc.)
  - Expire objects after specified days
  - Abort incomplete multipart uploads
- ✅ Optional custom bucket policy (JSON)

---

## Usage Examples

### 1. Minimal Configuration (Defaults)

Creates a secure S3 bucket with default settings:

```hcl
module "simple_bucket" {
  source = "./modules/data/s3"

  bucket_name   = "my-app-bucket-dev"
  force_destroy = false

  tags = {
    Environment = "dev"
    Project     = "my-application"
  }
}
```

**Default settings applied:**
- Private ACL
- All public access blocked
- Versioning enabled
- AES256 encryption
- No access logging
- No lifecycle rules

---

### 2. Production Bucket with All Features

Complete production configuration with KMS encryption, logging, and lifecycle rules:

```hcl
module "prod_bucket" {
  source = "./modules/data/s3"

  bucket_name       = "my-app-bucket-prod"
  force_destroy     = false
  enable_versioning = true

  # Public access settings (defaults shown for clarity)
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_ownership        = "BucketOwnerPreferred"

  # KMS encryption with auto-created key
  sse_algorithm  = "aws:kms"
  create_kms_key = true

  # Access logging with dedicated logs bucket
  enable_access_logging = true
  create_logs_bucket    = true
  access_log_prefix     = "s3-access-logs/"

  # Lifecycle rules: transition to cheaper storage over time
  lifecycle_rules = [
    {
      id      = "intelligent-tiering"
      enabled = true
      prefix  = null

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER_IR"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ]

      expiration_days                        = 365
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  # Custom bucket policy
  attach_bucket_policy = true
  bucket_policy_json   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnEncryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::my-app-bucket-prod/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })

  tags = {
    Environment = "prod"
    Project     = "my-application"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}
```

---

### 3. Bucket with Existing KMS Key

Use an existing KMS key for encryption:

```hcl
module "kms_encrypted_bucket" {
  source = "./modules/data/s3"

  bucket_name       = "my-encrypted-bucket"
  enable_versioning = true

  # Use existing KMS key
  sse_algorithm        = "aws:kms"
  create_kms_key       = false
  existing_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
    Compliance  = "required"
  }
}
```

---

### 4. Bucket with Logging to Existing Logs Bucket

Use a centralized logs bucket:

```hcl
module "app_bucket_with_logging" {
  source = "./modules/data/s3"

  bucket_name = "my-app-data-bucket"

  # Use existing central logs bucket
  enable_access_logging     = true
  create_logs_bucket        = false
  existing_logs_bucket_name = "central-s3-logs-bucket"
  access_log_prefix         = "app-data-bucket-logs/"

  tags = {
    Environment = "production"
    Application = "data-processing"
  }
}
```

---

### 5. Archive Bucket with Lifecycle Management

Long-term archival with aggressive lifecycle policies:

```hcl
module "archive_bucket" {
  source = "./modules/data/s3"

  bucket_name       = "company-archives"
  force_destroy     = false
  enable_versioning = true

  lifecycle_rules = [
    {
      id      = "archive-to-glacier"
      enabled = true
      prefix  = "archives/"

      transitions = [
        {
          days          = 7
          storage_class = "STANDARD_IA"
        },
        {
          days          = 30
          storage_class = "GLACIER_IR"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      expiration_days                        = 2555  # ~7 years
      abort_incomplete_multipart_upload_days = 3
    },
    {
      id      = "temp-files-cleanup"
      enabled = true
      prefix  = "temp/"

      transitions = []

      expiration_days                        = 30
      abort_incomplete_multipart_upload_days = 1
    }
  ]

  tags = {
    Environment = "production"
    DataType    = "long-term-archive"
    Retention   = "7-years"
  }
}
```

---

### 6. Public Static Website Bucket

Bucket configured for public website hosting (public access enabled):

```hcl
module "website_bucket" {
  source = "./modules/data/s3"

  bucket_name   = "my-static-website"
  force_destroy = true

  # Allow public access for website
  acl                     = "public-read"
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  enable_versioning = false

  tags = {
    Environment = "production"
    Type        = "static-website"
  }
}
```

---

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `bucket_name` | Name of the S3 bucket | `string` | - | yes |
| `force_destroy` | Delete all objects on bucket destroy | `bool` | `false` | no |
| `acl` | Canned ACL to apply (private, public-read, etc.) | `string` | `"private"` | no |
| `object_ownership` | Object ownership setting | `string` | `"BucketOwnerPreferred"` | no |
| `block_public_acls` | Block public ACLs | `bool` | `true` | no |
| `block_public_policy` | Block public bucket policies | `bool` | `true` | no |
| `ignore_public_acls` | Ignore public ACLs | `bool` | `true` | no |
| `restrict_public_buckets` | Restrict public bucket policies | `bool` | `true` | no |
| `enable_versioning` | Enable bucket versioning | `bool` | `true` | no |
| `sse_algorithm` | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| `create_kms_key` | Create a new KMS key for the bucket | `bool` | `false` | no |
| `existing_kms_key_arn` | Existing KMS key ARN to use | `string` | `null` | no |
| `enable_access_logging` | Enable access logging for the bucket | `bool` | `false` | no |
| `create_logs_bucket` | Create a dedicated logs bucket | `bool` | `true` | no |
| `existing_logs_bucket_name` | Existing logs bucket name | `string` | `null` | no |
| `access_log_prefix` | Prefix for access logs in the logs bucket | `string` | `"logs/"` | no |
| `lifecycle_rules` | List of lifecycle rules | `list(object)` | `[]` | no |
| `attach_bucket_policy` | Attach a bucket policy | `bool` | `false` | no |
| `bucket_policy_json` | Bucket policy JSON string | `string` | `""` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

### Lifecycle Rules Object Schema

```hcl
{
  id                                     = string           # Unique identifier for the rule
  enabled                                = bool             # Enable/disable the rule
  prefix                                 = optional(string) # Filter by prefix (null for all objects)
  transitions                            = list(object({    # Storage class transitions
    days          = number                                  # Days after creation
    storage_class = string                                  # Target storage class
  }))
  expiration_days                        = optional(number) # Days until objects expire
  abort_incomplete_multipart_upload_days = optional(number, 7) # Days to abort incomplete uploads
}
```

**Supported Storage Classes:**
- `STANDARD_IA` - Infrequent Access
- `ONEZONE_IA` - One Zone Infrequent Access
- `INTELLIGENT_TIERING` - Intelligent Tiering
- `GLACIER_IR` - Glacier Instant Retrieval
- `GLACIER` - Glacier Flexible Retrieval
- `DEEP_ARCHIVE` - Glacier Deep Archive

---

## Outputs

| Name | Description | Type |
|------|-------------|------|
| `bucket_id` | ID of the S3 bucket | `string` |
| `bucket_arn` | ARN of the S3 bucket | `string` |
| `bucket_region` | Region where the bucket is created | `string` |
| `logs_bucket_id` | ID of logs bucket (if created) | `string` |
| `kms_key_arn` | KMS key ARN used for encryption (if any) | `string` |

### Output Usage Example

```hcl
module "my_bucket" {
  source = "./modules/data/s3"
  
  bucket_name = "example-bucket"
  
  tags = {
    Environment = "dev"
  }
}

# Reference outputs
output "bucket_details" {
  value = {
    id     = module.my_bucket.bucket_id
    arn    = module.my_bucket.bucket_arn
    region = module.my_bucket.bucket_region
  }
}
```

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.14.1 |
| aws | >= 6.22.1 |

---

## Security Best Practices

This module implements the following security best practices by default:

1. **🔒 Private by Default** - All buckets are private with public access blocked
2. **🔐 Encryption at Rest** - All data encrypted with AES256 or KMS
3. **📋 Versioning** - Enabled by default to protect against accidental deletion
4. **🛡️ Ownership Controls** - BucketOwnerPreferred to ensure proper ACL behavior
5. **📊 Access Logging** - Optional centralized logging for audit trails
6. **♻️ Lifecycle Management** - Automatic cost optimization through storage tiering
7. **🚫 Force Destroy Protection** - Disabled by default to prevent accidental data loss

---

## Notes

- **KMS Encryption**: When using `aws:kms`, either set `create_kms_key = true` or provide an `existing_kms_key_arn`
- **Access Logging**: If `create_logs_bucket = false`, you must provide `existing_logs_bucket_name`
- **Bucket Naming**: Bucket names must be globally unique across all AWS accounts
- **Lifecycle Rules**: Transitions must be in order from more frequent to less frequent storage classes
- **Force Destroy**: Use with caution - when enabled, Terraform will delete all objects during bucket destruction

---

## License

This module is maintained as part of the AWS infrastructure project.

---

## Authors

Amara Vinay

---

## Support

For issues or questions, please contact the infrastructure team or open an issue in the project repository.