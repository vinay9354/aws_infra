variable "vpc_id" {
  description = "ID of the VPC where the subnet will be created"
  type        = string
}

variable "name" {
  description = "Name of the subnet (used in Name tag)"
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR block for the subnet"
  type        = string
}

variable "ipv6_cidr_block" {
  description = "IPv6 CIDR block for the subnet"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "Availability Zone for the subnet"
  type        = string
}

variable "map_public_ip_on_launch" {
  description = "Whether to assign a public IP by default to instances launched in this subnet"
  type        = bool
  default     = false
}

variable "assign_ipv6_address_on_creation" {
  description = "Whether to assign IPv6 address on creation"
  type        = bool
  default     = false
}

variable "create_route_table" {
  description = "Whether to create a new route table or use an existing one"
  type        = bool
  default     = true
}

variable "existing_route_table_id" {
  description = "ID of existing route table to associate (when create_route_table = false)"
  type        = string
  default     = null
}

variable "route_cidr_block" {
  description = "Destination CIDR block for the main route in the route table (e.g. 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "route_ipv6_cidr_block" {
  description = "Destination IPv6 CIDR block for the main route in the route table (e.g. ::/0)"
  type        = string
  default     = null
}

variable "route_target_type" {
  description = "Type of target for the main route: igw | natgw | tgw | vpce | eni | pcx"
  type        = string
  default     = "igw"

  validation {
    condition = contains(
      ["igw", "natgw", "tgw", "vpce", "eni", "pcx"],
      var.route_target_type
    )
    error_message = "route_target_type must be one of: igw, natgw, tgw, vpce, eni, pcx."
  }
}

variable "route_target_id" {
  description = "ID of the route target (e.g. IGW ID, NAT GW ID, TGW ID, VPC endpoint ID, ENI ID, VPC peering connection ID). Set to null or empty string to skip creating the main route."
  type        = string
  default     = null
}

variable "extra_routes" {
  description = <<EOT
Additional routes to add to the subnet's route table.

Each route object:
  - destination_cidr_block: destination IPv4 CIDR (optional if destination_ipv6_cidr_block or destination_prefix_list_id is set)
  - destination_ipv6_cidr_block: destination IPv6 CIDR (optional if destination_cidr_block or destination_prefix_list_id is set)
  - destination_prefix_list_id: destination prefix list ID (optional if destination_cidr_block or destination_ipv6_cidr_block is set)
  - target_type: igw | natgw | tgw | vpce | eni | pcx
  - target_id: ID of the target (IGW/NATGW/TGW/VPCE/ENI/PCX)
EOT
  type = list(object({
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    target_type                 = string
    target_id                   = string
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.extra_routes :
      contains(["igw", "natgw", "tgw", "vpce", "eni", "pcx"], r.target_type)
    ])
    error_message = "In extra_routes, target_type must be one of: igw, natgw, tgw, vpce, eni, pcx."
  }

  validation {
    condition = alltrue([
      for r in var.extra_routes :
      (r.destination_cidr_block != null && r.destination_cidr_block != "") ||
      (r.destination_ipv6_cidr_block != null && r.destination_ipv6_cidr_block != "") ||
      (r.destination_prefix_list_id != null && r.destination_prefix_list_id != "")
    ])
    error_message = "Each extra route must have at least one destination (destination_cidr_block, destination_ipv6_cidr_block, or destination_prefix_list_id)."
  }
}

variable "tags" {
  description = "Base tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

variable "subnet_tags" {
  description = "Additional tags to apply to the subnet"
  type        = map(string)
  default     = {}
}

variable "route_table_tags" {
  description = "Additional tags to apply to the route table"
  type        = map(string)
  default     = {}
}
