variable "name" {
  description = "Name of the VPC (used in Name tag)"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC (used when not using IPAM)"
  type        = string
  default     = null

  # Must choose either cidr_block OR ipv4_ipam_pool_id, but not both
  validation {
    condition = (
      (var.cidr_block != null && var.ipv4_ipam_pool_id == null) ||
      (var.cidr_block == null && var.ipv4_ipam_pool_id != null)
    )
    error_message = "You must provide either cidr_block OR ipv4_ipam_pool_id, but not both."
  }
}

variable "ipv4_ipam_pool_id" {
  description = "ID of the IPv4 IPAM pool from which to allocate a CIDR (optional)"
  type        = string
  default     = null
}

variable "ipv4_netmask_length" {
  description = "Netmask length used when allocating from the IPv4 IPAM pool (required if ipv4_ipam_pool_id is set)"
  type        = number
  default     = null

  validation {
    condition = (
      var.ipv4_ipam_pool_id == null || var.ipv4_netmask_length != null
    )
    error_message = "When ipv4_ipam_pool_id is set, ipv4_netmask_length must also be set."
  }
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_ipv6" {
  description = "Whether to assign an IPv6 CIDR block to the VPC"
  type        = bool
  default     = false
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated"], var.instance_tenancy)
    error_message = "instance_tenancy must be either \"default\" or \"dedicated\"."
  }
}

variable "create_igw" {
  description = "Whether to create and attach an Internet Gateway to this VPC"
  type        = bool
  default     = false
}

variable "igw_tags" {
  description = "Additional tags to apply specifically to the Internet Gateway"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_logs_destination_type" {
  description = "Destination type for VPC Flow Logs: cloud-watch-logs or s3"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_logs_destination_type)
    error_message = "flow_logs_destination_type must be either \"cloud-watch-logs\" or \"s3\"."
  }
}

variable "flow_logs_traffic_type" {
  description = "The type of traffic to log: ACCEPT, REJECT, or ALL"
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be one of ACCEPT, REJECT, or ALL."
  }
}

variable "flow_logs_log_group_name" {
  description = "Custom CloudWatch Log Group name for VPC Flow Logs (optional). If null, a default name is used."
  type        = string
  default     = null
}

variable "flow_logs_retention_in_days" {
  description = "Retention in days for Flow Logs CloudWatch Log Group"
  type        = number
  default     = 30
}

variable "flow_logs_s3_bucket_arn" {
  description = "S3 bucket ARN for VPC Flow Logs (required if destination type is s3)"
  type        = string
  default     = null

  validation {
    condition = (
      var.flow_logs_destination_type != "s3" ||
      (var.flow_logs_destination_type == "s3" && var.flow_logs_s3_bucket_arn != null)
    )
    error_message = "When flow_logs_destination_type is \"s3\", flow_logs_s3_bucket_arn must be set."
  }
}

variable "flow_logs_s3_key_prefix" {
  description = "Prefix for S3 objects when destination type is s3"
  type        = string
  default     = "vpc-flow-logs/"
}

variable "flow_logs_max_aggregation_interval" {
  description = "Maximum interval of time during which a flow is captured and aggregated into one flow log record (60 or 600 seconds)"
  type        = number
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "flow_logs_max_aggregation_interval must be either 60 or 600."
  }
}
