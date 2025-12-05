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

  # Default: no ingress rules
  default = []

  # Validation: if a rule sets `self = true` it must NOT set any other source fields
  validation {
    condition = alltrue([
      for r in var.ingress_rules :
      (
        r.self == true
        ? (
          length(coalesce(r.cidr_blocks, [])) == 0 &&
          length(coalesce(r.ipv6_cidr_blocks, [])) == 0 &&
          length(coalesce(r.prefix_list_ids, [])) == 0 &&
          r.source_security_group_id == null
        )
        : true
      )
    ])
    error_message = "Ingress rule validation: a rule with `self = true` must not also specify cidr_blocks, ipv6_cidr_blocks, prefix_list_ids or source_security_group_id."
  }

  # Validation: each rule must specify at least one source (cidr/ipv6/prefix/source_security_group_id/self)
  validation {
    condition = alltrue([
      for r in var.ingress_rules :
      (
        (length(coalesce(r.cidr_blocks, [])) +
          length(coalesce(r.ipv6_cidr_blocks, [])) +
          length(coalesce(r.prefix_list_ids, [])) +
          (r.source_security_group_id != null ? 1 : 0) +
          (r.self ? 1 : 0)
        ) > 0
      )
    ])
    error_message = "Ingress rule validation: each rule must specify at least one source: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, source_security_group_id or self."
  }

  # Validation: from_port must be <= to_port for each rule
  validation {
    condition = alltrue([
      for r in var.ingress_rules :
      r.from_port <= r.to_port
    ])
    error_message = "Ingress rule validation: from_port must be less than or equal to to_port."
  }
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

  # Validation: prevent invalid combinations when `self = true`
  validation {
    condition = alltrue([
      for r in var.egress_rules :
      (
        r.self == true
        ? (
          length(coalesce(r.cidr_blocks, [])) == 0 &&
          length(coalesce(r.ipv6_cidr_blocks, [])) == 0 &&
          length(coalesce(r.prefix_list_ids, [])) == 0 &&
          r.source_security_group_id == null
        )
        : true
      )
    ])
    error_message = "Egress rule validation: a rule with `self = true` must not also specify cidr_blocks, ipv6_cidr_blocks, prefix_list_ids or source_security_group_id."
  }

  # Validation: each rule must specify at least one source
  validation {
    condition = alltrue([
      for r in var.egress_rules :
      (
        (length(coalesce(r.cidr_blocks, [])) +
          length(coalesce(r.ipv6_cidr_blocks, [])) +
          length(coalesce(r.prefix_list_ids, [])) +
          (r.source_security_group_id != null ? 1 : 0) +
          (r.self ? 1 : 0)
        ) > 0
      )
    ])
    error_message = "Egress rule validation: each rule must specify at least one source: cidr_blocks, ipv6_cidr_blocks, prefix_list_ids, source_security_group_id or self."
  }

  # Validation: from_port must be <= to_port for each rule
  validation {
    condition = alltrue([
      for r in var.egress_rules :
      r.from_port <= r.to_port
    ])
    error_message = "Egress rule validation: from_port must be less than or equal to to_port."
  }
}
