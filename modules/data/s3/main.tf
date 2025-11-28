# -----------------------
# S3 Bucket
# -----------------------
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    {
      Name = var.bucket_name
    },
    var.tags
  )
}

# Ownership controls (required for ACLs in new provider versions)
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = var.object_ownership
  }
}

# Public access block (best practice: block everything by default)
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# ACL (private by default)
resource "aws_s3_bucket_acl" "this" {
  depends_on = [
    aws_s3_bucket_ownership_controls.this,
    aws_s3_bucket_public_access_block.this
  ]

  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# -----------------------
# Encryption
# -----------------------

resource "aws_kms_key" "this" {
  count = var.create_kms_key && var.sse_algorithm == "aws:kms" ? 1 : 0

  description             = "KMS key for S3 bucket ${var.bucket_name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    {
      Name = "${var.bucket_name}-kms"
    },
    var.tags
  )
}

locals {
  kms_key_id = var.sse_algorithm == "aws:kms" ? (
    var.create_kms_key ? aws_kms_key.this[0].arn : var.existing_kms_key_arn
  ) : null
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = local.kms_key_id
    }
  }
}

# -----------------------
# Logging
# -----------------------

# Optional dedicated log bucket
resource "aws_s3_bucket" "logs" {
  count = var.enable_access_logging && var.create_logs_bucket ? 1 : 0

  bucket        = "${var.bucket_name}-logs"
  force_destroy = true

  tags = merge(
    {
      Name = "${var.bucket_name}-logs"
      Type = "access-logs"
    },
    var.tags
  )
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = var.enable_access_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  count  = var.enable_access_logging && var.create_logs_bucket ? 1 : 0
  bucket = aws_s3_bucket.logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "logs" {
  count = var.enable_access_logging && var.create_logs_bucket ? 1 : 0

  depends_on = [
    aws_s3_bucket_ownership_controls.logs,
    aws_s3_bucket_public_access_block.logs
  ]

  bucket = aws_s3_bucket.logs[0].id
  acl    = "log-delivery-write"
}

# Attach logging to main bucket
resource "aws_s3_bucket_logging" "this" {
  count         = var.enable_access_logging ? 1 : 0
  bucket        = aws_s3_bucket.this.id
  target_prefix = var.access_log_prefix
  target_bucket = var.create_logs_bucket ? aws_s3_bucket.logs[0].id : var.existing_logs_bucket_name

}

# -----------------------
# Lifecycle rules
# -----------------------
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = length(var.lifecycle_rules) > 0 ? 1 : 0
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = coalesce(rule.value.prefix, "")
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days == null ? [] : [1]
        content {
          days = rule.value.expiration_days
        }
      }

      abort_incomplete_multipart_upload {
        days_after_initiation = rule.value.abort_incomplete_multipart_upload_days
      }
    }
  }
}

# -----------------------
# Bucket Policy (optional)
# -----------------------
resource "aws_s3_bucket_policy" "this" {
  count  = var.attach_bucket_policy && var.bucket_policy_json != "" ? 1 : 0
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json
}
