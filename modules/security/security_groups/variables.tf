variable "name" {
  description = "Name of the security group"
  type        = string
}

variable "description" {
  description = "Description of the security group"
  type        = string
  default     = "Managed by Terraform"
}

variable "vpc_id" {
  description = "VPC ID where security group will be created"
  type        = string
}

variable "tags" {
  description = "Additional tags for the security group"
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "List of ingress rules."
  type = list(object({
    description              = optional(string, null)
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    prefix_list_ids          = optional(list(string), [])
    source_security_group_id = optional(string, null)
    self                     = optional(bool, false)
  }))

  default = []
}

variable "egress_rules" {
  description = "List of egress rules."

  type = list(object({
    description              = optional(string, null)
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), [])
    ipv6_cidr_blocks         = optional(list(string), [])
    prefix_list_ids          = optional(list(string), [])
    source_security_group_id = optional(string, null)
    self                     = optional(bool, false)
  }))

  # default: allow all egress
  default = [
    {
      description              = "Allow all outbound IPv4 and IPv6"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      cidr_blocks              = ["0.0.0.0/0"]
      ipv6_cidr_blocks         = ["::/0"]
      prefix_list_ids          = []
      source_security_group_id = null
      self                     = false
    }
  ]
}
