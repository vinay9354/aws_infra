resource "aws_vpc" "this" {
  # IPv4: static CIDR or from IPAM pool
  cidr_block = var.ipv4_ipam_pool_id == null ? var.cidr_block : null

  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_ipam_pool_id == null ? null : var.ipv4_netmask_length

  instance_tenancy     = var.instance_tenancy
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  # Optional IPv6 from Amazon-provided range
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    { Name = var.name },
    var.tags
  )
}

# Optional Internet Gateway
resource "aws_internet_gateway" "this" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name = "${var.name}-igw"
    },
    var.tags,
    var.igw_tags
  )
}

# Data source for AWS-managed KMS key for CloudWatch Logs
data "aws_kms_key" "cloudwatch_logs" {
  count = local.flow_logs_to_cloudwatch && var.flow_logs_enable_kms_encryption ? 1 : 0

  key_id = "alias/aws/logs"
}

# Optional VPC Flow Logs
resource "aws_cloudwatch_log_group" "flow_logs" {
  count = local.flow_logs_to_cloudwatch ? 1 : 0

  name              = coalesce(var.flow_logs_log_group_name, "/aws/vpc/${var.name}-flow-logs")
  retention_in_days = var.flow_logs_retention_in_days
  skip_destroy      = var.flow_logs_log_group_skip_destroy
  kms_key_id        = var.flow_logs_enable_kms_encryption ? data.aws_kms_key.cloudwatch_logs[0].arn : null

  tags = merge(
    {
      Name = "${var.name}-flow-logs"
    },
    var.tags
  )
}

resource "aws_iam_role" "flow_logs" {
  count = local.flow_logs_to_cloudwatch ? 1 : 0

  name = "${var.name}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name}-flow-logs-role"
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "flow_logs" {
  count = local.flow_logs_to_cloudwatch ? 1 : 0

  name = "${var.name}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "this" {
  count = local.create_flow_logs ? 1 : 0

  vpc_id = aws_vpc.this.id


  traffic_type             = var.flow_logs_traffic_type
  log_destination_type     = var.flow_logs_destination_type
  max_aggregation_interval = var.flow_logs_max_aggregation_interval

  # Destination ARN (CloudWatch Logs uses the log group ARN; S3 uses bucket ARN + optional prefix)
  log_destination = local.flow_logs_to_cloudwatch ? aws_cloudwatch_log_group.flow_logs[0].arn : (local.flow_logs_to_s3 ? "${var.flow_logs_s3_bucket_arn}/${trim(var.flow_logs_s3_key_prefix, "/")}/" : null)

  iam_role_arn = local.flow_logs_to_cloudwatch ? aws_iam_role.flow_logs[0].arn : null

  tags = merge(
    {
      Name = "${var.name}-flow-logs"
    },
    var.tags
  )
}
