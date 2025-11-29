output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "IPv6 CIDR block of the VPC (if enabled)"
  value       = aws_vpc.this.ipv6_cidr_block
}

output "default_security_group_id" {
  description = "Default security group ID of the VPC"
  value       = aws_vpc.this.default_security_group_id
}

output "igw_id" {
  description = "ID of the Internet Gateway (null if not created)"
  value       = var.create_igw ? aws_internet_gateway.this[0].id : null
}

output "flow_logs_id" {
  description = "ID of the VPC Flow Log (null if not enabled)"
  value       = var.enable_flow_logs ? aws_flow_log.this[0].id : null
}

output "flow_logs_log_group_name" {
  description = "CloudWatch Log Group name used for VPC Flow Logs (null if not using CloudWatch)"
  value       = local.flow_logs_to_cloudwatch ? aws_cloudwatch_log_group.flow_logs[0].name : null
}

output "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN used for VPC Flow Logs (null if not using S3)"
  value       = local.flow_logs_to_s3 ? var.flow_logs_s3_bucket_arn : null
}
