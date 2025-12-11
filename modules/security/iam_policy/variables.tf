variable "name" {
  description = "The name of the policy"
  type        = string

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 128 && can(regex("^[\\w+=,.@-]+", var.name))
    error_message = "Policy name must be between 1 and 128 characters and can only contain alphanumeric characters and the following specials: _+=,.@-"
  }
}

variable "path" {
  description = "Path in which to create the policy"
  type        = string
  default     = "/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "Path must begin and end with a forward slash (/)."
  }
}

variable "description" {
  description = "Description of the IAM policy"
  type        = string
  default     = "Managed by Terraform"

  validation {
    condition     = length(var.description) <= 1000
    error_message = "Description must be less than or equal to 1000 characters."
  }
}

variable "policy" {
  description = "The policy document. This is a JSON formatted string"
  type        = string

  validation {
    condition     = can(jsondecode(var.policy))
    error_message = "Policy must be a valid JSON string."
  }
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}