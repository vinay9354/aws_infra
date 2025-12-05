# ----------------
# Common Variables
# ----------------
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}

variable "allowed_account_ids" {
  description = "List of allowed AWS account IDs"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ----------------
# Subnet Variables
# ----------------
variable "public_subnets" {
  description = "Map of public subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    # optional extra routes for the subnet with default empty list
    extra_routes = optional(list(object({
      destination_cidr_block      = optional(string)
      destination_ipv6_cidr_block = optional(string)
      destination_prefix_list_id  = optional(string)
      target_type                 = string
      target_id                   = string
    })), [])
    tags        = optional(map(string), {})
    subnet_tags = optional(map(string), {})
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnet configurations"
  type = map(object({
    cidr_block        = string
    availability_zone = string

    extra_routes = optional(list(object({
      destination_cidr_block      = optional(string)
      destination_ipv6_cidr_block = optional(string)
      destination_prefix_list_id  = optional(string)
      target_type                 = string
      target_id                   = string
    })), [])
    tags        = optional(map(string), {})
    subnet_tags = optional(map(string), {})
  }))
  default = {}
}

