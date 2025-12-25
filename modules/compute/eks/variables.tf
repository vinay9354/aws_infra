variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster and its nodes will be provisioned"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster (ENIs) will be provisioned"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "A list of subnet IDs where the EKS Control Plane ENIs will be provisioned. If not provided, `subnet_ids` will be used."
  type        = list(string)
  default     = []
}

variable "node_group_subnet_ids" {
  description = "A list of subnet IDs where the EKS Node Groups will be provisioned. If not provided, `subnet_ids` will be used."
  type        = list(string)
  default     = []
}

variable "enable_cluster_creator_admin_permissions" {

  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via Access Entry. Defaults to true."

  type = bool

  default = true

}



variable "cluster_endpoint_public_access" {

  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"

  type = bool

  default = true

}



variable "cluster_endpoint_public_access_cidrs" {

  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"

  type = list(string)

  default = ["0.0.0.0/0"]

}



variable "cluster_endpoint_private_access" {

  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"

  type = bool

  default = true

}



variable "cluster_service_ipv4_cidr" {

  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks."

  type = string

  default = null

}



variable "cluster_ip_family" {

  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`."

  type = string

  default = "ipv4"

  validation {

    condition = contains(["ipv4", "ipv6"], var.cluster_ip_family)

    error_message = "The cluster_ip_family must be either 'ipv4' or 'ipv6'."

  }

}



variable "cluster_service_ipv6_cidr" {

  description = "The CIDR block to assign Kubernetes pod and service IP addresses from if `ipv6` was specified when the cluster was created."

  type = string

  default = null

}



variable "cluster_enabled_log_types" {

  description = "A list of the desired control plane logging to enable"

  type = list(string)

  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

}



variable "create_cluster_security_group" {

  description = "Defines if a new security group should be created for the cluster"

  type = bool

  default = true

}



variable "cluster_security_group_id" {

  description = "Existing security group ID to attach to the cluster. Required if `create_cluster_security_group` is false."

  type = string

  default = ""

}



variable "cluster_additional_security_group_ids" {

  description = "List of additional, existing security group IDs to attach to the cluster control plane"

  type = list(string)

  default = []

}



variable "cluster_security_group_additional_rules" {

  description = "List of additional security group rules to add to the cluster security group"

  type = map(object({

    type = string

    from_port = number

    to_port = number

    protocol = string

    cidr_blocks = optional(list(string))

    source_security_group_id = optional(string)

    description = optional(string)

  }))

  default = {}

}



variable "node_security_group_additional_rules" {

  description = "List of additional security group rules to add to the node security group"

  type = map(object({

    type = string

    from_port = number

    to_port = number

    protocol = string

    cidr_blocks = optional(list(string))

    source_security_group_id = optional(string)

    description = optional(string)

  }))

  default = {}

}



variable "node_security_group_enable_recommended_rules" {

  description = "Determines whether to enable recommended security group rules (like egress to 0.0.0.0/0) for nodes. Set to false if you want strict control."

  type = bool

  default = true

}



variable "create_kms_key" {
  description = "Controls if a KMS key for cluster encryption should be created"
  type        = bool
  default     = false
}

variable "kms_key_description" {
  description = "The description of the key as viewed in AWS console"
  type        = string
  default     = "EKS Cluster Encryption Key"
}

variable "kms_key_deletion_window_in_days" {
  description = "The waiting period, specified in number of days"
  type        = number
  default     = 30
}

variable "kms_key_administrators" {
  description = "A list of IAM ARNs for [key administrators](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html#key-policy-default-allow-administrators). If no value is provided, the current caller identity is used to ensure at least one key admin is available"
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for EKS envelope encryption"
  type        = string
  default     = null
}

variable "enable_irsa" {
  description = "Determines whether to create an OpenID Connect Provider for EKS to enable IRSA"
  type        = bool
  default     = true
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain log events. Default retention - 90 days"
  type        = number
  default     = 90
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
  default     = null
}

variable "managed_node_groups" {
  description = "Map of managed node group definitions to create"
  type = map(object({
    name            = optional(string)
    use_name_prefix = optional(bool, true)

    subnet_ids = optional(list(string))

    min_size     = optional(number, 1)
    max_size     = optional(number, 3)
    desired_size = optional(number, 1)

    ami_type       = optional(string, "AL2_x86_64")
    ami_id         = optional(string)              # For Custom AMI
    capacity_type  = optional(string, "ON_DEMAND") # ON_DEMAND or SPOT
    instance_types = optional(list(string), ["t3.medium"])
    disk_size      = optional(number, 20)

    # Update Config
    update_config = optional(object({
      max_unavailable            = optional(number)
      max_unavailable_percentage = optional(number)
    }))

    labels = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])

    tags = optional(map(string), {})

    # Launch Template support
    create_launch_template = optional(bool, true)
    launch_template_name   = optional(string)
    block_device_mappings  = optional(any, {}) # For custom volumes

    # IAM
    iam_role_arn                 = optional(string)
    create_iam_role              = optional(bool, true)
    iam_role_additional_policies = optional(map(string), {})
  }))
  default = {}
}



variable "self_managed_node_groups" {

  description = "Map of self-managed node group definitions to create"

  type = map(object({

    name = optional(string)

    use_name_prefix = optional(bool, true)



    subnet_ids = optional(list(string))



    min_size = optional(number, 1)

    max_size = optional(number, 3)

    desired_capacity = optional(number, 1)



    instance_type = optional(string, "t3.medium")

    ami_id = optional(string) # Optional, defaults to EKS optimized AMI



    # User data settings

    bootstrap_extra_args = optional(string, "")

    user_data_template_path = optional(string) # Path to custom user data template

    platform = optional(string, "linux") # "linux" or "windows"



    key_name = optional(string)



    block_device_mappings = optional(any, {})



    tags = optional(map(string), {})



    # IAM

    iam_role_arn = optional(string)

    create_iam_role = optional(bool, true)

    iam_role_additional_policies = optional(map(string), {})

  }))

  default = {}

}



variable "fargate_profiles" {

  description = "Map of Fargate Profile definitions to create"

  type = map(object({

    name = string

    selectors = list(object({

      namespace = string

      labels = optional(map(string))

    }))

    subnet_ids = optional(list(string))

    tags = optional(map(string), {})



    iam_role_arn = optional(string)

    create_iam_role = optional(bool, true)

    iam_role_additional_policies = optional(map(string), {})

  }))

  default = {}

}



variable "cluster_addons" {

  description = "Map of cluster add-ons to enable"

  type = map(object({

    addon_version = optional(string)

    resolve_conflicts_on_create = optional(string, "OVERWRITE")

    resolve_conflicts_on_update = optional(string, "OVERWRITE")

    configuration_values = optional(string)

    service_account_role_arn = optional(string)

    preserve = optional(bool, false)

    timeouts = optional(object({

      create = optional(string)

      update = optional(string)

      delete = optional(string)

    }))

  }))

  default = {}

}



variable "enable_karpenter" {

  description = "Determines whether to tag the security group and subnets for Karpenter usage"

  type = bool

  default = false

}



variable "access_entries" {

  description = "Map of access entries to add to the cluster (replaces aws-auth)"

  type = map(object({

    principal_arn = string

    kubernetes_groups = optional(list(string), [])

    type = optional(string, "STANDARD")

    user_name = optional(string)

    policy_associations = optional(map(object({

      policy_arn = string

      access_scope = object({

        type = string

        namespaces = optional(list(string))

      })

    })), {})

  }))

  default = {}

}



# Legacy AWS Auth variables

variable "manage_aws_auth_configmap" {

  description = "Determines whether to manage the aws-auth configmap"

  type = bool

  default = false

}



variable "aws_auth_roles" {

  description = "List of role maps to add to the aws-auth configmap"

  type = list(object({

    rolearn = string

    username = string

    groups = list(string)

  }))

  default = []

}



variable "aws_auth_users" {

  description = "List of user maps to add to the aws-auth configmap"

  type = list(object({

    userarn = string

    username = string

    groups = list(string)

  }))

  default = []

}



variable "aws_auth_accounts" {

  description = "List of account maps to add to the aws-auth configmap"

  type = list(string)

  default = []

}



variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
