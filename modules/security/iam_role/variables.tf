variable "name" {
  description = "The name of the IAM role"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64 && can(regex("^[\\w+=,.@-]+", var.name))
    error_message = "Role name must be between 1 and 64 characters and can only contain alphanumeric characters and the following specials: _+=,.@-"
  }
}

variable "assume_role_policy" {
  description = "The policy that grants an entity permission to assume the role (JSON string)"
  type        = string

  validation {
    condition     = can(jsondecode(var.assume_role_policy))
    error_message = "assume_role_policy must be a valid JSON string."
  }
}

variable "description" {
  description = "Description of the IAM role"
  type        = string
  default     = "Managed by Terraform"

  validation {
    condition     = length(var.description) <= 1000
    error_message = "Description must be less than or equal to 1000 characters."
  }
}

variable "path" {
  description = "Path to the IAM role"
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "Path must begin and end with a forward slash (/)."
  }
}

variable "force_detach_policies" {
  description = "Whether to force detaching any policies the role has before destroying it"
  type        = bool
  default     = false
}

variable "max_session_duration" {
  description = "Maximum session duration (in seconds) that you want to set for the specified role"
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 (1 hour) and 43200 (12 hours)."
  }
}

variable "permissions_boundary" {
  description = "ARN of the policy that is used to set the permissions boundary for the role"
  type        = string
  default     = null
}

variable "policy_arns" {
  description = "List of ARNs of IAM policies to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for this role"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
