variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters, start and end with a lowercase letter or number, and contain only lowercase letters, numbers, hyphens, and periods."
  }
}

variable "force_destroy" {
  description = "Delete all objects on bucket destroy."
  type        = bool
  default     = false
}

variable "acl" {
  description = "Canned ACL to apply."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "public-read", "public-read-write", "authenticated-read", "aws-exec-read", "log-delivery-write"], var.acl)
    error_message = "ACL must be one of: private, public-read, public-read-write, authenticated-read, aws-exec-read, log-delivery-write."
  }
}

variable "object_ownership" {
  description = "Object ownership setting: BucketOwnerPreferred, ObjectWriter, etc."
  type        = string
  default     = "BucketOwnerPreferred"

  validation {
    condition     = contains(["BucketOwnerPreferred", "ObjectWriter", "BucketOwnerEnforced"], var.object_ownership)
    error_message = "Object ownership must be one of: BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced."
  }
}

variable "block_public_acls" {
  type    = bool
  default = true
}

variable "block_public_policy" {
  type    = bool
  default = true
}

variable "ignore_public_acls" {
  type    = bool
  default = true
}

variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "enable_versioning" {
  description = "Enable bucket versioning."
  type        = bool
  default     = true
}

# Encryption
variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)."
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be either \"AES256\" or \"aws:kms\"."
  }
}

variable "create_kms_key" {
  description = "Create a new KMS key for the bucket when using aws:kms."
  type        = bool
  default     = false

  validation {
    condition     = var.sse_algorithm == "aws:kms" || var.create_kms_key == false
    error_message = "create_kms_key can only be true when sse_algorithm is \"aws:kms\"."
  }
}

variable "existing_kms_key_arn" {
  description = "Existing KMS key ARN to use if not creating a new one."
  type        = string
  default     = null

  validation {
    condition = (
      var.sse_algorithm != "aws:kms" ||
      var.create_kms_key == true ||
      var.existing_kms_key_arn != null
    )
    error_message = "When sse_algorithm is \"aws:kms\" and create_kms_key is false, you must provide an existing_kms_key_arn."
  }

  validation {
    condition     = var.existing_kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.existing_kms_key_arn))
    error_message = "existing_kms_key_arn must be a valid KMS key ARN format."
  }
}

# Logging
variable "enable_access_logging" {
  description = "Enable access logging for the bucket."
  type        = bool
  default     = false
}

variable "create_logs_bucket" {
  description = "Create a dedicated logs bucket if access logging is enabled."
  type        = bool
  default     = true
}

variable "existing_logs_bucket_name" {
  description = "Existing logs bucket name (used if create_logs_bucket = false)."
  type        = string
  default     = null

  validation {
    condition = (
      var.enable_access_logging == false ||
      var.create_logs_bucket == true ||
      var.existing_logs_bucket_name != null
    )
    error_message = "When enable_access_logging is true and create_logs_bucket is false, you must provide an existing_logs_bucket_name."
  }
}

variable "access_log_prefix" {
  description = "Prefix for access logs in the logs bucket."
  type        = string
  default     = "logs/"
}

# Lifecycle rules
variable "lifecycle_rules" {
  description = "List of lifecycle rules."
  type = list(object({
    id      = string
    enabled = bool
    prefix  = optional(string)
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration_days                        = optional(number)
    abort_incomplete_multipart_upload_days = optional(number, 7)
  }))

  default = []
}

# Bucket policy
variable "attach_bucket_policy" {
  description = "Attach a bucket policy."
  type        = bool
  default     = false

  validation {
    condition     = var.attach_bucket_policy == false || var.bucket_policy_json != ""
    error_message = "When attach_bucket_policy is true, bucket_policy_json must be provided."
  }
}

variable "bucket_policy_json" {
  description = "Bucket policy JSON string."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
