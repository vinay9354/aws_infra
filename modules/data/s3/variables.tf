variable "bucket_name" {
  description = "Name of the S3 bucket."
  type        = string
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
}

variable "object_ownership" {
  description = "Object ownership setting: BucketOwnerPreferred, ObjectWriter, etc."
  type        = string
  default     = "BucketOwnerPreferred"
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
}

variable "create_kms_key" {
  description = "Create a new KMS key for the bucket when using aws:kms."
  type        = bool
  default     = false
}

variable "existing_kms_key_arn" {
  description = "Existing KMS key ARN to use if not creating a new one."
  type        = string
  default     = null
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