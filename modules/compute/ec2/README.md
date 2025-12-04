# EC2 Instance Module

This Terraform module creates and manages AWS EC2 instances with comprehensive configuration options including IAM role management, key pair generation, spot instance support, network interface creation, and instance state management.

## Features

- **Instance Types**: Support for both on-demand and spot instances
- **IAM Role Management**: Create new IAM roles or use existing ones with automatic SSM and CloudWatch policies
- **Key Pair Management**: Generate key pairs and securely store them in SSM Parameter Store
- **Network Configuration**: Create or attach network interfaces with flexible configuration
- **Storage Options**: Support for root, additional EBS volumes, and ephemeral storage
- **Instance State Management**: Control instance state (running/stopped) through Terraform
- **Elastic IP Support**: Optional EIP allocation and association
- **Security**: IMDSv2 enabled by default, encryption by default
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

  # Optional: set validity period
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

### Core Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_instance | Whether to create the EC2 instance | `bool` | `true` | no |
| name | Name to be used on EC2 instance created | `string` | n/a | yes |
| ami_id | ID of AMI to use for the instance | `string` | n/a | yes |
| instance_type | The type of instance to start | `string` | `"t3.micro"` | no |
| subnet_id | The VPC Subnet ID to launch in | `string` | n/a | yes |
| availability_zone | AZ to start the instance in | `string` | `null` | no |
| security_group_ids | A list of security group IDs to associate with | `list(string)` | `[]` | no |
| associate_public_ip_address | Whether to associate a public IP address | `bool` | `false` | no |
| user_data | The user data to provide when launching the instance | `string` | `null` | no |
| user_data_base64 | Base64-encoded binary data | `string` | `null` | no |

### IAM Role Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_iam_role | Whether to create a new IAM role | `bool` | `false` | no |
| existing_iam_role_name | Name of existing IAM role to use | `string` | `null` | no |
| iam_instance_profile | IAM Instance Profile to use (if not creating role) | `string` | `null` | no |
| attach_ssm_policy | Attach AmazonSSMManagedInstanceCore policy | `bool` | `true` | no |
| attach_cloudwatch_agent_policy | Attach CloudWatchAgentServerPolicy | `bool` | `true` | no |
| additional_iam_policy_arns | Additional IAM policy ARNs to attach | `list(string)` | `[]` | no |

### Key Pair Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_key_pair | Whether to create a new key pair | `bool` | `false` | no |
| key_name | Key name to use (if not creating) | `string` | `null` | no |
| key_pair_name | Name for the new key pair | `string` | `null` | no |
| key_pair_algorithm | Algorithm (RSA or ED25519) | `string` | `"RSA"` | no |
| key_pair_rsa_bits | RSA key bits (2048, 3072, or 4096) | `number` | `4096` | no |
| store_key_pair_in_ssm | Store keys in SSM Parameter Store | `bool` | `true` | no |
| private_key_ssm_parameter_name | SSM parameter name for private key | `string` | `null` | no |
| public_key_ssm_parameter_name | SSM parameter name for public key | `string` | `null` | no |

### Spot Instance Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| use_spot_instance | Use spot instance instead of on-demand | `bool` | `false` | no |
| spot_price | Maximum price to request on spot market | `string` | `null` | no |
| spot_type | Spot request type (one-time or persistent) | `string` | `"persistent"` | no |
| spot_instance_interruption_behavior | Behavior on interruption (hibernate, stop, terminate) | `string` | `"stop"` | no |
| spot_wait_for_fulfillment | Wait for spot request fulfillment | `bool` | `true` | no |
| spot_valid_until | End date/time of request (RFC3339) | `string` | `null` | no |
| spot_block_duration_minutes | Duration in minutes (60-360) | `number` | `null` | no |

### Network Interface Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| create_network_interfaces | Create new network interfaces | `bool` | `false` | no |
| network_interface_configs | Map of network interface configurations | `map(object)` | `{}` | no |
| additional_network_interfaces | Map of existing NICs to attach | `map(object)` | `{}` | no |

### Instance State Management

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| manage_instance_state | Manage instance state with Terraform | `bool` | `false` | no |
| instance_state | Desired state (running or stopped) | `string` | `"running"` | no |
| force_instance_state_change | Force state change | `bool` | `false` | no |

### Storage Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| root_block_device | Root block device configuration | `map(any)` | `null` | no |
| ebs_block_devices | Additional EBS block devices | `list(map(string))` | `[]` | no |
| ephemeral_block_devices | Ephemeral volumes | `list(map(string))` | `[]` | no |
| additional_ebs_volumes | Separately created EBS volumes | `map(object)` | `{}` | no |
| ebs_optimized | Enable EBS optimization | `bool` | `true` | no |

### Other Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_monitoring | Enable detailed monitoring | `bool` | `false` | no |
| create_eip | Create and associate Elastic IP | `bool` | `false` | no |
| metadata_options | Instance metadata options | `map(string)` | See below | no |
| disable_api_termination | Enable termination protection | `bool` | `false` | no |
| source_dest_check | Enable source/destination checking | `bool` | `true` | no |
| tenancy | Instance tenancy | `string` | `"default"` | no |
| placement_group | Placement group name | `string` | `null` | no |
| cpu_credits | CPU credits (unlimited or standard) | `string` | `null` | no |
| tags | Tags to assign to resources | `map(string)` | `{}` | no |
| volume_tags | Tags for volumes | `map(string)` | `{}` | no |

### Default Metadata Options

```hcl
{
  http_endpoint               = "enabled"
  http_tokens                 = "required"      # IMDSv2 required
  http_put_response_hop_limit = 1
  instance_metadata_tags      = "disabled"
}
```

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
- **Encryption**: EBS volumes are encrypted by default
- **Key Storage**: Private keys are stored as SecureString in SSM with AWS managed KMS
- **IAM Policies**: SSM and CloudWatch policies are attached by default for management

### Cost Optimization

- Use `use_spot_instance = true` for non-critical workloads (up to 90% savings)
- Use `gp3` volumes instead of `gp2` for better price/performance
- Enable `manage_instance_state` to stop instances when not needed

### Networking

- When `create_network_interfaces = true`, new NICs are created and attached
- When `create_network_interfaces = false`, use `additional_network_interfaces` to attach existing NICs
- The primary network interface is always created with the instance

### Key Pair Management

- Generated private keys are automatically stored in SSM Parameter Store
- Use the `private_key_pem` output (sensitive) to retrieve the key
- Retrieve keys from SSM using: `aws ssm get-parameter --name <parameter_name> --with-decryption`

### Spot Instances

- Spot instances can be interrupted by AWS with 2-minute warning
- Use `spot_instance_interruption_behavior = "stop"` to preserve data
- Set `spot_type = "persistent"` to automatically request a new spot instance after interruption
- Monitor spot instance status with the `spot_request_state` output

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

Module managed by Flentas Technologies.

## License

Apache 2 Licensed. See LICENSE for full details.