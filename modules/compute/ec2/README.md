# EC2 Instance Module

This Terraform module creates and manages AWS EC2 instances with comprehensive configuration options including IAM role management, key pair generation, spot instance support, network interface creation, block device configuration, and instance state management.

## Features

- **Instance Types**: Support for both on-demand and Spot instances
- **IAM Role Management**: Create new IAM roles or use existing ones with automatic SSM and CloudWatch policies
- **Key Pair Management**: Generate key pairs and securely store them in SSM Parameter Store
- **Network Configuration**: Create or attach network interfaces with flexible configuration
- **Storage Options**: Support for root, additional EBS volumes, and ephemeral storage
- **Instance State Management**: Control instance state (running/stopped) through Terraform
- **Elastic IP Support**: Optional EIP allocation and association
- **Security**: IMDSv2 enabled by default, encryption recommended for EBS
- **Monitoring**: Optional detailed monitoring and CloudWatch integration
- **Lifecycle Management**: Prevent unnecessary instance recreation

## Usage

### Basic Example - Simple EC2 Instance

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "my-application-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-12345678"

  security_group_ids          = ["sg-12345678"]
  associate_public_ip_address = true

  tags = {
    Environment = "production"
    Application = "web-server"
  }
}
```

### Example with IAM Role Creation

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "my-app-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Create a new IAM role with default SSM and CloudWatch policies
  create_iam_role                 = true
  attach_ssm_policy               = true  # Default: true
  attach_cloudwatch_agent_policy  = true  # Default: true

  # Attach additional custom policies
  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::123456789012:policy/MyCustomPolicy"
  ]

  tags = {
    Environment = "production"
  }
}
```

### Example with Existing IAM Role

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "my-app-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Use an existing IAM role
  create_iam_role        = false
  existing_iam_role_name = "my-existing-ec2-role"

  tags = {
    Environment = "production"
  }
}
```

### Example with Key Pair Generation and SSM Storage

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "secure-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Create and store key pair in SSM
  create_key_pair         = true
  key_pair_name           = "my-secure-key"  # Optional, defaults to "{name}-key"
  key_pair_algorithm      = "RSA"            # RSA or ED25519
  key_pair_rsa_bits       = 4096             # 2048, 3072, or 4096
  store_key_pair_in_ssm   = true             # Default: true

  # Optional: custom SSM parameter names
  private_key_ssm_parameter_name = "/my-app/keys/private-key"
  public_key_ssm_parameter_name  = "/my-app/keys/public-key"

  tags = {
    Environment = "production"
  }
}

# Retrieve the private key from SSM (for use in another resource)
data "aws_ssm_parameter" "private_key" {
  name       = module.ec2_instance.private_key_ssm_parameter_name
  depends_on = [module.ec2_instance]
}
```

### Example with Spot Instance

```hcl
module "ec2_spot_instance" {
  source = "../../modules/compute/ec2"

  name          = "batch-processing-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "c5.2xlarge"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Enable spot instance
  use_spot_instance                  = true
  spot_price                         = "0.30"        # Max price, defaults to on-demand if not set
  spot_type                          = "persistent" # one-time or persistent
  spot_instance_interruption_behavior = "stop"       # hibernate, stop, or terminate
  spot_wait_for_fulfillment          = true

  # Optional: set validity period (RFC3339 UTC)
  spot_valid_until = "2024-12-31T23:59:59Z"

  tags = {
    Environment = "development"
    Workload    = "batch-processing"
  }
}
```

### Example with Custom Network Interfaces

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "multi-nic-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.large"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Create additional network interfaces
  create_network_interfaces = true
  network_interface_configs = {
    management = {
      subnet_id          = "subnet-87654321"
      device_index       = 1
      security_group_ids = ["sg-management"]
      private_ip         = "10.0.2.100"
      source_dest_check  = false
      description        = "Management network interface"
    }
    data = {
      subnet_id          = "subnet-11223344"
      device_index       = 2
      security_group_ids = ["sg-data"]
      description        = "Data transfer network interface"
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### Example with Existing Network Interfaces

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "server-with-existing-nic"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "m5.large"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Attach existing network interfaces
  create_network_interfaces = false
  additional_network_interfaces = {
    existing_nic = {
      network_interface_id = "eni-1234567890abcdef0"
      device_index         = 1
    }
  }

  tags = {
    Environment = "production"
  }
}
```

### Example with Instance State Management

```hcl
module "ec2_instance" {
  source = "../../modules/compute/ec2"

  name          = "scheduled-server"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Manage instance state
  manage_instance_state       = true
  instance_state              = "stopped"  # running or stopped
  force_instance_state_change = false

  tags = {
    Environment = "development"
    Schedule    = "business-hours-only"
  }
}
```

### Complete Example with All Features

```hcl
module "ec2_complete" {
  source = "../../modules/compute/ec2"

  name               = "production-app-server"
  ami_id             = "ami-0c55b159cbfafe1f0"
  instance_type      = "t3.large"
  subnet_id          = "subnet-12345678"
  availability_zone  = "us-east-1a"

  security_group_ids          = ["sg-12345678"]
  associate_public_ip_address = true

  # IAM Role
  create_iam_role                = true
  attach_ssm_policy              = true
  attach_cloudwatch_agent_policy = true
  additional_iam_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  # Key Pair
  create_key_pair       = true
  key_pair_algorithm    = "RSA"
  key_pair_rsa_bits     = 4096
  store_key_pair_in_ssm = true

  # Storage
  root_block_device = {
    volume_type           = "gp3"
    volume_size           = 50
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = true
  }

  additional_ebs_volumes = {
    data = {
      device_name = "/dev/sdf"
      size        = 100
      type        = "gp3"
      encrypted   = true
    }
  }

  # Network
  create_network_interfaces = true
  network_interface_configs = {
    management = {
      subnet_id          = "subnet-87654321"
      device_index       = 1
      security_group_ids = ["sg-management"]
      description        = "Management interface"
    }
  }

  # Elastic IP
  create_eip = true

  # Monitoring and Metadata
  enable_monitoring = true
  ebs_optimized     = true

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Instance State
  manage_instance_state = true
  instance_state        = "running"

  # User Data
  user_data = file("${path.module}/scripts/user-data.sh")

  # Tags
  tags = {
    Environment = "production"
    Application = "web-server"
    ManagedBy   = "terraform"
  }

  volume_tags = {
    Backup = "daily"
  }
}
```

### Example - Cost-Optimized Spot Instance with Auto-Created IAM and Keys

```hcl
module "ec2_spot_dev" {
  source = "../../modules/compute/ec2"

  name          = "dev-workstation"
  ami_id        = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"
  subnet_id     = "subnet-12345678"

  security_group_ids = ["sg-12345678"]

  # Spot instance for cost savings
  use_spot_instance                  = true
  spot_type                          = "persistent"
  spot_instance_interruption_behavior = "stop"

  # Auto-create IAM role with SSM access
  create_iam_role   = true
  attach_ssm_policy = true

  # Auto-create and store key pair
  create_key_pair       = true
  store_key_pair_in_ssm = true

  # Control instance state
  manage_instance_state = true
  instance_state        = "stopped"  # Start in stopped state

  tags = {
    Environment = "development"
    CostCenter  = "engineering"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |
| tls | >= 4.0 |

## Inputs

> The Inputs section below is kept in the original README format but updated to match `variables.tf` (types, defaults and validations). Deprecated / removed variables (e.g., `spot_block_duration_minutes`) are not listed.

### Core Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_instance | Whether to create the EC2 instance | `bool` | `true` | no |
| name | Name to be used on EC2 instance created | `string` | n/a | yes |
| ami_id | ID of AMI to use for the instance | `string` | n/a | yes |
| instance_type | The type of instance to start | `string` | `"t3.micro"` | no |
| key_name | Key name of the Key Pair to use for the instance (used if `create_key_pair` is false) | `string` | `null` | no |
| subnet_id | The VPC Subnet ID to launch in | `string` | n/a | yes |
| availability_zone | AZ to start the instance in | `string` | `null` | no |
| security_group_ids | A list of security group IDs to associate with | `list(string)` | `[]` | no |
| associate_public_ip_address | Whether to associate a public IP address with an instance in a VPC | `bool` | `false` | no |
| user_data | The user data to provide when launching the instance | `string` | `null` | no |
| user_data_base64 | Can be used instead of `user_data` to pass base64-encoded binary data directly | `string` | `null` | no |
| enable_monitoring | If true, the launched EC2 instance will have detailed monitoring enabled | `bool` | `false` | no |
| ebs_optimized | If true, the launched EC2 instance will be EBS-optimized | `bool` | `true` | no |
| source_dest_check | Controls if traffic is routed to the instance when the destination address does not match the instance | `bool` | `true` | no |
| disable_api_termination | If true, enables EC2 Instance Termination Protection | `bool` | `false` | no |
| instance_initiated_shutdown_behavior | Shutdown behavior for the instance (`stop` or `terminate`) | `string` | `"stop"` | no |
| placement_group | The Placement Group to start the instance in | `string` | `null` | no |
| tenancy | The tenancy of the instance (`default`, `dedicated`, or `host`) | `string` | `"default"` | no |
| host_id | ID of a dedicated host that the instance will be assigned to | `string` | `null` | no |
| cpu_core_count | Sets the number of CPU cores for an instance | `number` | `null` | no |
| cpu_threads_per_core | Sets the number of CPU threads per core for an instance | `number` | `null` | no |
| cpu_credits | The credit option for CPU usage (`unlimited` or `standard`) | `string` | `null` | no |
| tags | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| volume_tags | A mapping of tags to assign to the devices created by the instance at launch time | `map(string)` | `{}` | no |
| create_eip | Whether to create an Elastic IP for the instance | `bool` | `false` | no |

Notes (validations):
- `instance_initiated_shutdown_behavior` must be either `"stop"` or `"terminate"`.
- `tenancy` must be one of: `"default"`, `"dedicated"`, `"host"`.
- `cpu_credits` (if provided) must be `"standard"` or `"unlimited"`.

### Storage Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| root_block_device | Customize details about the root block device of the instance | `object({ optional(string) volume_type, optional(number) volume_size, optional(number) iops, optional(number) throughput, optional(bool) delete_on_termination, optional(bool) encrypted, optional(string) kms_key_id, optional(map(string)) tags })` | `null` | no |
| ebs_block_devices | Additional EBS block devices to attach to the instance | `list(object({ device_name = string, optional(string) volume_type, optional(number) volume_size, optional(number) iops, optional(number) throughput, optional(bool) delete_on_termination, optional(bool) encrypted, optional(string) kms_key_id, optional(string) snapshot_id, optional(map(string)) tags }))` | `[]` | no |
| ephemeral_block_devices | Customize Ephemeral (also known as Instance Store) volumes on the instance | `list(object({ device_name = string, virtual_name = string }))` | `[]` | no |
| additional_ebs_volumes | Map of additional EBS volumes to create and attach to the instance | `map(object({ device_name = string, size = number, optional(string) type, optional(number) iops, optional(number) throughput, optional(bool) encrypted, optional(string) kms_key_id, optional(string) snapshot_id, optional(bool) force_detach, optional(bool) skip_destroy, optional(map(string)) tags }))` | `{}` | no |
| ebs_optimized | Enable EBS optimization | `bool` | `true` | no |

Notes (validations):
- `root_block_device.volume_size` (if provided) must be > 0.
- `root_block_device.volume_type` and `ebs_block_devices[*].volume_type` (if provided) must be one of: `gp2`, `gp3`, `io1`, `io2`, `sc1`, `st1`, `standard`.
- Each entry in `ebs_block_devices` must have a non-empty `device_name`.

### Network Interface Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_network_interfaces | Whether to create new network interfaces | `bool` | `false` | no |
| network_interface_configs | Map of network interface configurations to create | `map(object({ subnet_id = string, device_index = number, optional(list(string)) security_group_ids, optional(list(string)) private_ips, optional(string) private_ip, optional(bool) source_dest_check, optional(string) description, optional(map(string)) tags }))` | `{}` | no |
| additional_network_interfaces | Map of additional existing network interfaces to attach to the instance | `map(object({ network_interface_id = string, device_index = number }))` | `{}` | no |
| network_interfaces | Customize network interfaces to be attached at instance boot time | `list(object({ device_index = number, network_interface_id = string, optional(bool) delete_on_termination }))` | `[]` | no |

### IAM Role Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_iam_role | Whether to create a new IAM role for the instance | `bool` | `false` | no |
| existing_iam_role_name | Name of an existing IAM role to use (if create_iam_role is false) | `string` | `null` | no |
| iam_instance_profile | IAM Instance Profile to launch the instance with (used if create_iam_role is false and existing_iam_role_name is null) | `string` | `null` | no |
| attach_ssm_policy | Whether to attach the AmazonSSMManagedInstanceCore policy to the IAM role | `bool` | `true` | no |
| attach_cloudwatch_agent_policy | Whether to attach the CloudWatchAgentServerPolicy to the IAM role | `bool` | `true` | no |
| additional_iam_policy_arns | List of additional IAM policy ARNs to attach to the role | `list(string)` | `[]` | no |

Behavior notes:
- If `create_iam_role = true` the module creates a role and an instance profile unless overridden.
- If `create_iam_role = false` and `existing_iam_role_name` is supplied, the module will use the existing role.

### Key Pair Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_key_pair | Whether to create a new key pair for the instance | `bool` | `false` | no |
| key_pair_name | Name for the key pair (if not specified, uses instance name with '-key' suffix) | `string` | `null` | no |
| key_pair_algorithm | Algorithm to use for key pair generation (`RSA` or `ED25519`) | `string` | `"RSA"` | no |
| key_pair_rsa_bits | Number of bits for RSA key (if algorithm is RSA) | `number` | `4096` | no |
| store_key_pair_in_ssm | Whether to store the private and public keys in SSM Parameter Store | `bool` | `true` | no |
| private_key_ssm_parameter_name | SSM parameter name for storing the private key | `string` | `null` | no |
| public_key_ssm_parameter_name | SSM parameter name for storing the public key | `string` | `null` | no |

Validations:
- `key_pair_algorithm` must be `RSA` or `ED25519`.
- If `key_pair_algorithm = "RSA"`, `key_pair_rsa_bits` must be one of: `2048`, `3072`, `4096`.

### Spot Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| use_spot_instance | Whether to use spot instance instead of on-demand | `bool` | `false` | no |
| spot_price | The maximum price to request on the spot market. Defaults to on-demand price if not specified | `string` | `null` | no |
| spot_wait_for_fulfillment | If set, Terraform will wait for the Spot Request to be fulfilled | `bool` | `true` | no |
| spot_type | The Spot Instance request type (`one-time` or `persistent`) | `string` | `"persistent"` | no |
| spot_instance_interruption_behavior | Indicates whether a Spot Instance stops or terminates when it is interrupted (`hibernate`, `stop`, or `terminate`) | `string` | `"stop"` | no |
| spot_valid_until | The end date and time of the request in RFC3339 format (`YYYY-MM-DDTHH:MM:SSZ`) | `string` | `null` | no |

Validations:
- `spot_type` must be `one-time` or `persistent`.
- `spot_instance_interruption_behavior` must be `hibernate`, `stop`, or `terminate`.
- `spot_valid_until` (if set) must match RFC3339 UTC format (YYYY-MM-DDTHH:MM:SSZ).

> Note: `spot_block_duration_minutes` has been removed / deprecated and is not supported by this module.

### Instance State Management

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| manage_instance_state | Whether to manage the instance state with aws_ec2_instance_state resource | `bool` | `false` | no |
| instance_state | The desired state of the instance (running or stopped) | `string` | `"running"` | no |
| force_instance_state_change | Whether to force the instance state change | `bool` | `false` | no |

Validation:
- `instance_state` must be either `running` or `stopped`.

### Default Metadata Options

```hcl
{
  http_endpoint               = "enabled"
  http_tokens                 = "required"      # IMDSv2 required
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "disabled"
}
```

Validation summary for `metadata_options`:
- `http_endpoint`: must be `enabled` or `disabled`.
- `http_tokens`: must be `required` or `optional`.
- `http_put_response_hop_limit`: integer between 0 and 64.
- `instance_metadata_tags`: must be `enabled` or `disabled`.

## Outputs

### Instance Outputs

| Name | Description |
|------|-------------|
| instance_id | The ID of the instance |
| instance_arn | The ARN of the instance |
| instance_state | The state of the instance |
| instance_type | The type of the instance |
| private_ip | The private IP address |
| public_ip | The public IP address |
| private_dns | The private DNS name |
| public_dns | The public DNS name |
| availability_zone | The availability zone |
| key_name | The key name |
| subnet_id | The VPC subnet ID |
| security_groups | Associated security groups |
| primary_network_interface_id | Primary network interface ID |

### IAM Outputs

| Name | Description |
|------|-------------|
| iam_role_name | The name of the IAM role |
| iam_role_arn | The ARN of the IAM role |
| iam_role_id | The ID of the IAM role |
| iam_instance_profile_name | The instance profile name |
| iam_instance_profile_arn | The instance profile ARN |

### Key Pair Outputs

| Name | Description |
|------|-------------|
| key_pair_name | The name of the key pair |
| key_pair_id | The ID of the key pair |
| key_pair_arn | The ARN of the key pair |
| key_pair_fingerprint | The MD5 fingerprint |
| private_key_ssm_parameter_name | SSM parameter name for private key |
| public_key_ssm_parameter_name | SSM parameter name for public key |
| private_key_pem | The private key in PEM format (sensitive) |
| public_key_openssh | The public key in OpenSSH format |

### Spot Instance Outputs

| Name | Description |
|------|-------------|
| spot_request_id | The Spot Instance request ID |
| spot_request_state | The Spot request state |
| spot_bid_status | The Spot bid status |
| spot_instance_id | The Instance ID (if fulfilled) |

### Network Interface Outputs

| Name | Description |
|------|-------------|
| created_network_interface_ids | Map of created NIC IDs |
| created_network_interface_private_ips | Map of NIC private IPs |
| created_network_interface_mac_addresses | Map of NIC MAC addresses |

### Storage Outputs

| Name | Description |
|------|-------------|
| root_block_device | Root block device info |
| ebs_block_devices | EBS block device info |
| additional_ebs_volume_ids | Map of additional volume IDs |
| additional_ebs_volume_arns | Map of additional volume ARNs |

### Elastic IP Outputs

| Name | Description |
|------|-------------|
| eip_id | The Elastic IP ID |
| eip_public_ip | The Elastic IP address |
| eip_allocation_id | The EIP allocation ID |

### State Management Outputs

| Name | Description |
|------|-------------|
| managed_instance_state | The managed state |

## Notes

### Security Best Practices

- **IMDSv2 Required**: The module enforces IMDSv2 by default for enhanced security
- **Encryption**: Use encrypted EBS volumes where required by your security policy
- **Key Storage**: Private keys stored by this module (when generated) are stored as SSM `SecureString` using the AWS-managed KMS key by default
- **IAM Policies**: SSM and CloudWatch policies are attached by default for management

### Cost Optimization

- Use `use_spot_instance = true` for non-critical workloads (can yield significant savings)
- Prefer `gp3` volumes over `gp2` for cost/performance where appropriate
- Enable `manage_instance_state` to stop instances when not in use

### Networking

- When `create_network_interfaces = true`, new NICs are created and attached
- When `create_network_interfaces = false`, use `additional_network_interfaces` to attach existing NICs
- Ensure subnet and IP selections for additional NICs do not conflict with existing allocations

### Key Pair Management

- Generated private keys are automatically stored in SSM Parameter Store (when `store_key_pair_in_ssm = true`)
- Use the `private_key_pem` output (sensitive) or the SSM parameter to retrieve the key
- Retrieve keys from SSM using: `aws ssm get-parameter --name <parameter_name> --with-decryption`

### Spot Instances

- Spot instances can be interrupted by AWS with a short warning
- Use `spot_instance_interruption_behavior = "stop"` to preserve attached EBS data where possible
- Monitor Spot lifecycle and `spot_request_state` output

### Instance State Management

- Enable `manage_instance_state = true` to control instance state through Terraform
- Useful for scheduled workloads or cost optimization
- Use with caution in production to avoid unexpected state changes

## Examples

Complete working examples are available in the [examples](../../../examples/ec2/) directory:

- `basic/` - Simple EC2 instance
- `with-iam-role/` - Instance with auto-created IAM role
- `with-key-pair/` - Instance with generated key pair
- `spot-instance/` - Spot instance configuration
- `multi-nic/` - Multiple network interfaces
- `complete/` - All features combined

## Accessing SSH Keys from SSM

After creating an instance with `create_key_pair = true`, retrieve the private key:

```bash
# Using AWS CLI
aws ssm get-parameter \
  --name "/<instance-name>/ec2/private-key" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text > private-key.pem

chmod 400 private-key.pem

# SSH to the instance
ssh -i private-key.pem ec2-user@<instance-ip>
```

Or use Terraform data source:

```hcl
data "aws_ssm_parameter" "private_key" {
  name       = module.ec2_instance.private_key_ssm_parameter_name
  depends_on = [module.ec2_instance]
}

# Write to local file (use with caution)
resource "local_file" "private_key" {
  content         = data.aws_ssm_parameter.private_key.value
  filename        = "${path.module}/private-key.pem"
  file_permission = "0400"
}
```

## Authors

Module managed by vinay datta.

## License

Apache 2 Licensed. See LICENSE for full details.