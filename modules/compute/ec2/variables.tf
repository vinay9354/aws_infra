variable "create_instance" {
  description = "Whether to create the EC2 instance"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
}

variable "ami_id" {
  description = "ID of AMI to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance (used if create_key_pair is false)"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with (used if create_iam_role is false and existing_iam_role_name is null)"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address with an instance in a VPC"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = null
}

variable "user_data_base64" {
  description = "Can be used instead of user_data to pass base64-encoded binary data directly"
  type        = string
  default     = null
}

variable "enable_monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled"
  type        = bool
  default     = false
}

variable "ebs_optimized" {
  description = "If true, the launched EC2 instance will be EBS-optimized"
  type        = bool
  default     = true
}

variable "source_dest_check" {
  description = "Controls if traffic is routed to the instance when the destination address does not match the instance"
  type        = bool
  default     = true
}

variable "disable_api_termination" {
  description = "If true, enables EC2 Instance Termination Protection"
  type        = bool
  default     = false
}

variable "instance_initiated_shutdown_behavior" {
  description = "Shutdown behavior for the instance (stop or terminate)"
  type        = string
  default     = "stop"
  validation {
    condition     = contains(["stop", "terminate"], var.instance_initiated_shutdown_behavior)
    error_message = "Instance initiated shutdown behavior must be either 'stop' or 'terminate'."
  }
}

variable "placement_group" {
  description = "The Placement Group to start the instance in"
  type        = string
  default     = null
}

variable "tenancy" {
  description = "The tenancy of the instance (default, dedicated, or host)"
  type        = string
  default     = "default"
  validation {
    condition     = contains(["default", "dedicated", "host"], var.tenancy)
    error_message = "Tenancy must be one of: default, dedicated, host."
  }
}

variable "host_id" {
  description = "ID of a dedicated host that the instance will be assigned to"
  type        = string
  default     = null
}

variable "cpu_core_count" {
  description = "Sets the number of CPU cores for an instance"
  type        = number
  default     = null
}

variable "cpu_threads_per_core" {
  description = "Sets the number of CPU threads per core for an instance"
  type        = number
  default     = null
}

variable "availability_zone" {
  description = "AZ to start the instance in"
  type        = string
  default     = null
}

# Root block device - tightened type and validation
variable "root_block_device" {
  description = "Customize details about the root block device of the instance"
  # Accept a structured object (nullable)
  type = object({
    volume_type           = optional(string)
    volume_size           = optional(number)
    iops                  = optional(number)
    throughput            = optional(number)
    delete_on_termination = optional(bool)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
  })
  default = null

  validation {
    condition = (
      var.root_block_device == null ||
      (
        (try(var.root_block_device.volume_size, null) == null || try(var.root_block_device.volume_size, 0) > 0) &&
        (try(var.root_block_device.volume_type, null) == null || contains(["gp2", "gp3", "io1", "io2", "sc1", "st1", "standard"], try(var.root_block_device.volume_type, "")))
      )
    )
    error_message = "If provided, root_block_device.volume_size must be > 0 and volume_type (if present) must be a valid EBS type (gp2,gp3,io1,io2,sc1,st1,standard)."
  }
}

# Additional EBS block devices - tightened type and validation
variable "ebs_block_devices" {
  description = "Additional EBS block devices to attach to the instance"
  type = list(object({
    device_name           = string
    volume_type           = optional(string)
    volume_size           = optional(number)
    iops                  = optional(number)
    throughput            = optional(number)
    delete_on_termination = optional(bool)
    encrypted             = optional(bool)
    kms_key_id            = optional(string)
    snapshot_id           = optional(string)
  }))
  default = []

  validation {
    condition = length(var.ebs_block_devices) == 0 || alltrue([
      for dev in var.ebs_block_devices : (
        length(trimspace(dev.device_name)) > 0 &&
        (try(dev.volume_size, null) == null || try(dev.volume_size, 0) > 0) &&
        (try(dev.volume_type, null) == null || contains(["gp2", "gp3", "io1", "io2", "sc1", "st1", "standard"], try(dev.volume_type, "gp3")))
      )
    ])
    error_message = "Each ebs_block_devices entry must have a non-empty device_name; if provided, volume_size must be > 0 and volume_type (if present) must be a valid EBS type."
  }
}

# Ephemeral (instance store) block devices
variable "ephemeral_block_devices" {
  description = "Customize Ephemeral (also known as Instance Store) volumes on the instance"
  type = list(object({
    device_name  = string
    virtual_name = string
  }))
  default = []
}

# Network interfaces passed inline to instance resources
variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type = list(object({
    device_index          = number
    network_interface_id  = string
    delete_on_termination = optional(bool)
  }))
  default = []
}

# Metadata options - tightened and validated
variable "metadata_options" {
  description = "Customize the metadata options of the instance"
  type = object({
    http_endpoint               = optional(string)
    http_tokens                 = optional(string)
    http_put_response_hop_limit = optional(number)
    instance_metadata_tags      = optional(string)
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  validation {
    condition = (
      contains(["enabled", "disabled"], try(var.metadata_options.http_endpoint, "enabled")) &&
      contains(["required", "optional"], try(var.metadata_options.http_tokens, "required")) &&
      try(var.metadata_options.http_put_response_hop_limit, 1) >= 0 &&
      try(var.metadata_options.http_put_response_hop_limit, 1) <= 64 &&
      contains(["enabled", "disabled"], try(var.metadata_options.instance_metadata_tags, "disabled"))
    )
    error_message = "metadata_options must contain valid values: http_endpoint (enabled|disabled), http_tokens (required|optional), http_put_response_hop_limit (0-64), instance_metadata_tags (enabled|disabled)."
  }
}

variable "cpu_credits" {
  description = "The credit option for CPU usage (unlimited or standard)"
  type        = string
  default     = null
  validation {
    condition     = var.cpu_credits == null || contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "cpu_credits must be either 'standard' or 'unlimited' if provided."
  }
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the devices created by the instance at launch time"
  type        = map(string)
  default     = {}
}

variable "create_eip" {
  description = "Whether to create an Elastic IP for the instance"
  type        = bool
  default     = false
}

variable "additional_ebs_volumes" {
  description = "Map of additional EBS volumes to create and attach to the instance"
  type = map(object({
    device_name  = string
    size         = number
    type         = optional(string)
    iops         = optional(number)
    throughput   = optional(number)
    encrypted    = optional(bool)
    kms_key_id   = optional(string)
    snapshot_id  = optional(string)
    force_detach = optional(bool)
    skip_destroy = optional(bool)
    tags         = optional(map(string))
  }))
  default = {}
}

variable "additional_network_interfaces" {
  description = "Map of additional existing network interfaces to attach to the instance"
  type = map(object({
    network_interface_id = string
    device_index         = number
  }))
  default = {}
}

# ===================================
# IAM Role Variables
# ===================================

variable "create_iam_role" {
  description = "Whether to create a new IAM role for the instance"
  type        = bool
  default     = false
}

variable "existing_iam_role_name" {
  description = "Name of an existing IAM role to use (if create_iam_role is false)"
  type        = string
  default     = null
}

variable "attach_ssm_policy" {
  description = "Whether to attach the AmazonSSMManagedInstanceCore policy to the IAM role"
  type        = bool
  default     = true
}

variable "attach_cloudwatch_agent_policy" {
  description = "Whether to attach the CloudWatchAgentServerPolicy to the IAM role"
  type        = bool
  default     = true
}

variable "additional_iam_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

# ===================================
# Key Pair Variables
# ===================================

variable "create_key_pair" {
  description = "Whether to create a new key pair for the instance"
  type        = bool
  default     = false
}

variable "key_pair_name" {
  description = "Name for the key pair (if not specified, uses instance name with '-key' suffix)"
  type        = string
  default     = null
}

variable "key_pair_algorithm" {
  description = "Algorithm to use for key pair generation (RSA or ED25519)"
  type        = string
  default     = "RSA"
  validation {
    condition     = contains(["RSA", "ED25519"], var.key_pair_algorithm)
    error_message = "Key pair algorithm must be either 'RSA' or 'ED25519'."
  }
}

variable "key_pair_rsa_bits" {
  description = "Number of bits for RSA key (if algorithm is RSA)"
  type        = number
  default     = 4096
  validation {
    condition     = contains([2048, 3072, 4096], var.key_pair_rsa_bits)
    error_message = "RSA bits must be 2048, 3072, or 4096."
  }
}

variable "store_key_pair_in_ssm" {
  description = "Whether to store the private and public keys in SSM Parameter Store"
  type        = bool
  default     = true
}

variable "private_key_ssm_parameter_name" {
  description = "SSM parameter name for storing the private key (if not specified, uses /{instance_name}/ec2/private-key)"
  type        = string
  default     = null
}

variable "public_key_ssm_parameter_name" {
  description = "SSM parameter name for storing the public key (if not specified, uses /{instance_name}/ec2/public-key)"
  type        = string
  default     = null
}

# ===================================
# Spot Instance Variables
# ===================================

variable "use_spot_instance" {
  description = "Whether to use spot instance instead of on-demand"
  type        = bool
  default     = false
}

variable "spot_price" {
  description = "The maximum price to request on the spot market. Defaults to on-demand price if not specified"
  type        = string
  default     = null
}

variable "spot_wait_for_fulfillment" {
  description = "If set, Terraform will wait for the Spot Request to be fulfilled"
  type        = bool
  default     = true
}

variable "spot_type" {
  description = "The Spot Instance request type (one-time or persistent)"
  type        = string
  default     = "persistent"
  validation {
    condition     = contains(["one-time", "persistent"], var.spot_type)
    error_message = "Spot type must be either 'one-time' or 'persistent'."
  }
}

variable "spot_instance_interruption_behavior" {
  description = "Indicates whether a Spot Instance stops or terminates when it is interrupted (hibernate, stop, or terminate)"
  type        = string
  default     = "stop"
  validation {
    condition     = contains(["hibernate", "stop", "terminate"], var.spot_instance_interruption_behavior)
    error_message = "Spot instance interruption behavior must be 'hibernate', 'stop', or 'terminate'."
  }
}

variable "spot_valid_until" {
  description = "The end date and time of the request in RFC3339 format (YYYY-MM-DDTHH:MM:SSZ)"
  type        = string
  default     = null
  validation {
    condition     = var.spot_valid_until == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$", var.spot_valid_until))
    error_message = "spot_valid_until must be in RFC3339 UTC format: YYYY-MM-DDTHH:MM:SSZ"
  }
}

# ===================================
# Network Interface Variables
# ===================================

variable "create_network_interfaces" {
  description = "Whether to create new network interfaces"
  type        = bool
  default     = false
}

variable "network_interface_configs" {
  description = "Map of network interface configurations to create"
  type = map(object({
    subnet_id          = string
    device_index       = number
    security_group_ids = optional(list(string))
    private_ips        = optional(list(string))
    private_ip         = optional(string)
    source_dest_check  = optional(bool)
    description        = optional(string)
    tags               = optional(map(string))
  }))
  default = {}
}

# ===================================
# Instance State Management Variables
# ===================================

variable "manage_instance_state" {
  description = "Whether to manage the instance state with aws_ec2_instance_state resource"
  type        = bool
  default     = false
}

variable "instance_state" {
  description = "The desired state of the instance (running or stopped)"
  type        = string
  default     = "running"
  validation {
    condition     = contains(["running", "stopped"], var.instance_state)
    error_message = "Instance state must be either 'running' or 'stopped'."
  }
}

variable "force_instance_state_change" {
  description = "Whether to force the instance state change"
  type        = bool
  default     = false
}
