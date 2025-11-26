output "bucket_id" {
  description = "ID of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Region of the bucket."
  value       = aws_s3_bucket.this.region
}

output "logs_bucket_id" {
  description = "ID of logs bucket if created."
  value       = try(aws_s3_bucket.logs[0].id, null)
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption (if any)."
  value       = local.kms_key_id
}
