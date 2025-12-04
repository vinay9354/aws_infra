# ========================================
# EC2 Module - Usage Examples
# ========================================
# This file contains various examples of how to use the EC2 module.
# Uncomment and modify the examples as needed for your use case.

# ========================================
# Example 1: Basic EC2 Instance
# ========================================

# module "basic_instance" {
#   source = "./"
#
#   name          = "basic-web-server"
#   ami_id        = "ami-0c55b159cbfafe1f0"  # Replace with your AMI
#   instance_type = "t3.medium"
#   subnet_id     = "subnet-12345678"  # Replace with your subnet
#
#   security_group_ids          = ["sg-12345678"]  # Replace with your security group
#   associate_public_ip_address = true
#
#   tags = {
#     Environment = "production"
#     Application = "web-server"
#   }
# }

# ========================================
# Example 2: Instance with Auto-Created IAM Role
# ========================================

# module "instance_with_iam" {
#   source = "./"
#
#   name          = "app-server-with-iam"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Create IAM role with default SSM and CloudWatch policies
#   create_iam_role                = true
#   attach_ssm_policy              = true
#   attach_cloudwatch_agent_policy = true
#
#   # Attach additional custom policies
#   additional_iam_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
#     "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
#   ]
#
#   tags = {
#     Environment = "production"
#     ManagedBy   = "terraform"
#   }
# }

# ========================================
# Example 3: Instance with Existing IAM Role
# ========================================

# module "instance_with_existing_iam" {
#   source = "./"
#
#   name          = "app-server-existing-role"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Use existing IAM role
#   create_iam_role        = false
#   existing_iam_role_name = "my-existing-ec2-role"
#
#   tags = {
#     Environment = "production"
#   }
# }

# ========================================
# Example 4: Instance with Auto-Generated Key Pair
# ========================================

# module "instance_with_keypair" {
#   source = "./"
#
#   name          = "secure-server"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Auto-create and store key pair in SSM
#   create_key_pair         = true
#   key_pair_name           = "my-secure-keypair"  # Optional
#   key_pair_algorithm      = "RSA"
#   key_pair_rsa_bits       = 4096
#   store_key_pair_in_ssm   = true
#
#   # Optional: Custom SSM parameter names
#   private_key_ssm_parameter_name = "/my-app/keys/private-key"
#   public_key_ssm_parameter_name  = "/my-app/keys/public-key"
#
#   tags = {
#     Environment = "production"
#     Security    = "high"
#   }
# }
#
# # Output the private key SSM parameter name
# output "private_key_location" {
#   value = module.instance_with_keypair.private_key_ssm_parameter_name
# }
#
# # Optionally retrieve the private key (be careful with this)
# data "aws_ssm_parameter" "private_key" {
#   name       = module.instance_with_keypair.private_key_ssm_parameter_name
#   depends_on = [module.instance_with_keypair]
# }

# ========================================
# Example 5: Spot Instance for Cost Savings
# ========================================

# module "spot_instance" {
#   source = "./"
#
#   name          = "batch-processing-spot"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "c5.2xlarge"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Enable spot instance
#   use_spot_instance                  = true
#   spot_price                         = "0.30"        # Max price per hour
#   spot_type                          = "persistent"  # or "one-time"
#   spot_instance_interruption_behavior = "stop"       # or "hibernate", "terminate"
#   spot_wait_for_fulfillment          = true
#
#   # Optional: set validity period
#   # spot_valid_until = "2024-12-31T23:59:59Z"
#
#   # Optional: block duration (60-360 minutes)
#   # spot_block_duration_minutes = 120
#
#   tags = {
#     Environment = "development"
#     Workload    = "batch-processing"
#     CostCenter  = "engineering"
#   }
# }
#
# # Monitor spot request status
# output "spot_request_state" {
#   value = module.spot_instance.spot_request_state
# }
#
# output "spot_instance_id" {
#   value = module.spot_instance.spot_instance_id
# }

# ========================================
# Example 6: Instance with Custom Network Interfaces
# ========================================

# module "multi_nic_instance" {
#   source = "./"
#
#   name          = "multi-nic-server"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "m5.large"
#   subnet_id     = "subnet-12345678"  # Primary subnet
#
#   security_group_ids = ["sg-12345678"]
#
#   # Create additional network interfaces
#   create_network_interfaces = true
#   network_interface_configs = {
#     management = {
#       subnet_id          = "subnet-management"
#       device_index       = 1
#       security_group_ids = ["sg-management"]
#       private_ip         = "10.0.2.100"
#       source_dest_check  = false
#       description        = "Management network interface"
#       tags = {
#         Type = "Management"
#       }
#     }
#     data = {
#       subnet_id          = "subnet-data"
#       device_index       = 2
#       security_group_ids = ["sg-data"]
#       description        = "Data transfer network interface"
#       tags = {
#         Type = "Data"
#       }
#     }
#   }
#
#   tags = {
#     Environment = "production"
#     Type        = "Network-Appliance"
#   }
# }

# ========================================
# Example 7: Instance with Existing Network Interfaces
# ========================================

# module "instance_with_existing_nic" {
#   source = "./"
#
#   name          = "server-existing-nic"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "m5.large"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Attach existing network interfaces
#   create_network_interfaces = false
#   additional_network_interfaces = {
#     existing_nic = {
#       network_interface_id = "eni-1234567890abcdef0"
#       device_index         = 1
#     }
#   }
#
#   tags = {
#     Environment = "production"
#   }
# }

# ========================================
# Example 8: Instance with State Management
# ========================================

# module "scheduled_instance" {
#   source = "./"
#
#   name          = "business-hours-server"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.medium"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Manage instance state through Terraform
#   manage_instance_state       = true
#   instance_state              = "stopped"  # "running" or "stopped"
#   force_instance_state_change = false
#
#   tags = {
#     Environment = "development"
#     Schedule    = "business-hours-only"
#   }
# }

# ========================================
# Example 9: Instance with Additional EBS Volumes
# ========================================

# module "instance_with_volumes" {
#   source = "./"
#
#   name          = "data-server"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "m5.xlarge"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # Custom root volume
#   root_block_device = {
#     volume_type           = "gp3"
#     volume_size           = 50
#     iops                  = 3000
#     throughput            = 125
#     encrypted             = true
#     delete_on_termination = true
#   }
#
#   # Additional EBS volumes (created separately and attached)
#   additional_ebs_volumes = {
#     data = {
#       device_name = "/dev/sdf"
#       size        = 100
#       type        = "gp3"
#       iops        = 3000
#       throughput  = 125
#       encrypted   = true
#     }
#     logs = {
#       device_name = "/dev/sdg"
#       size        = 50
#       type        = "gp3"
#       encrypted   = true
#     }
#     backup = {
#       device_name = "/dev/sdh"
#       size        = 200
#       type        = "gp3"
#       encrypted   = true
#       tags = {
#         Backup = "daily"
#       }
#     }
#   }
#
#   # Volume tags
#   volume_tags = {
#     BackupSchedule = "daily"
#   }
#
#   tags = {
#     Environment = "production"
#     Application = "database"
#   }
# }

# ========================================
# Example 10: Instance with Elastic IP
# ========================================

# module "instance_with_eip" {
#   source = "./"
#
#   name          = "bastion-host"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.micro"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids          = ["sg-bastion"]
#   associate_public_ip_address = true
#
#   # Create and associate Elastic IP
#   create_eip = true
#
#   tags = {
#     Environment = "production"
#     Role        = "bastion"
#   }
# }
#
# output "bastion_eip" {
#   value = module.instance_with_eip.eip_public_ip
# }

# ========================================
# Example 11: COMPLETE - All Features Combined
# ========================================

# module "complete_instance" {
#   source = "./"
#
#   name               = "production-complete-server"
#   ami_id             = "ami-0c55b159cbfafe1f0"
#   instance_type      = "t3.large"
#   subnet_id          = "subnet-12345678"
#   availability_zone  = "us-east-1a"
#
#   security_group_ids          = ["sg-12345678"]
#   associate_public_ip_address = true
#
#   # ===== IAM Role Configuration =====
#   create_iam_role                = true
#   attach_ssm_policy              = true
#   attach_cloudwatch_agent_policy = true
#   additional_iam_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
#     "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
#   ]
#
#   # ===== Key Pair Configuration =====
#   create_key_pair       = true
#   key_pair_algorithm    = "RSA"
#   key_pair_rsa_bits     = 4096
#   store_key_pair_in_ssm = true
#
#   # ===== Storage Configuration =====
#   root_block_device = {
#     volume_type           = "gp3"
#     volume_size           = 50
#     iops                  = 3000
#     throughput            = 125
#     encrypted             = true
#     delete_on_termination = true
#   }
#
#   additional_ebs_volumes = {
#     data = {
#       device_name = "/dev/sdf"
#       size        = 100
#       type        = "gp3"
#       encrypted   = true
#     }
#     logs = {
#       device_name = "/dev/sdg"
#       size        = 50
#       type        = "gp3"
#       encrypted   = true
#     }
#   }
#
#   # ===== Network Configuration =====
#   create_network_interfaces = true
#   network_interface_configs = {
#     management = {
#       subnet_id          = "subnet-management"
#       device_index       = 1
#       security_group_ids = ["sg-management"]
#       description        = "Management interface"
#     }
#   }
#
#   # ===== Elastic IP =====
#   create_eip = true
#
#   # ===== Monitoring and Metadata =====
#   enable_monitoring = true
#   ebs_optimized     = true
#
#   metadata_options = {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#     instance_metadata_tags      = "enabled"
#   }
#
#   # ===== Instance Configuration =====
#   disable_api_termination = true
#   enable_monitoring       = true
#
#   # ===== Instance State Management =====
#   manage_instance_state = true
#   instance_state        = "running"
#
#   # ===== User Data =====
#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y amazon-cloudwatch-agent
#     systemctl enable amazon-cloudwatch-agent
#     systemctl start amazon-cloudwatch-agent
#   EOF
#
#   # ===== Tags =====
#   tags = {
#     Environment = "production"
#     Application = "web-server"
#     ManagedBy   = "terraform"
#     CostCenter  = "engineering"
#   }
#
#   volume_tags = {
#     Backup = "daily"
#   }
# }
#
# # Outputs for complete instance
# output "complete_instance_id" {
#   value = module.complete_instance.instance_id
# }
#
# output "complete_instance_private_ip" {
#   value = module.complete_instance.private_ip
# }
#
# output "complete_instance_public_ip" {
#   value = module.complete_instance.public_ip
# }
#
# output "complete_instance_eip" {
#   value = module.complete_instance.eip_public_ip
# }
#
# output "complete_instance_iam_role" {
#   value = module.complete_instance.iam_role_name
# }
#
# output "complete_instance_key_location" {
#   value = module.complete_instance.private_key_ssm_parameter_name
# }

# ========================================
# Example 12: Spot Instance with All Auto-Created Resources
# ========================================

# module "spot_with_auto_resources" {
#   source = "./"
#
#   name          = "dev-workstation-spot"
#   ami_id        = "ami-0c55b159cbfafe1f0"
#   instance_type = "t3.large"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids = ["sg-12345678"]
#
#   # ===== Spot Configuration =====
#   use_spot_instance                  = true
#   spot_type                          = "persistent"
#   spot_instance_interruption_behavior = "stop"
#   spot_wait_for_fulfillment          = true
#
#   # ===== Auto-Create IAM Role =====
#   create_iam_role   = true
#   attach_ssm_policy = true
#
#   # ===== Auto-Create Key Pair =====
#   create_key_pair       = true
#   store_key_pair_in_ssm = true
#
#   # ===== Instance State Management =====
#   manage_instance_state = true
#   instance_state        = "stopped"  # Start stopped to save costs
#
#   tags = {
#     Environment = "development"
#     CostCenter  = "engineering"
#     Type        = "spot-instance"
#   }
# }

# ========================================
# Example 13: High-Performance Database Server
# ========================================

# module "database_server" {
#   source = "./"
#
#   name               = "postgres-primary"
#   ami_id             = "ami-0c55b159cbfafe1f0"
#   instance_type      = "r5.2xlarge"  # Memory optimized
#   subnet_id          = "subnet-database"
#   availability_zone  = "us-east-1a"
#
#   security_group_ids          = ["sg-database"]
#   associate_public_ip_address = false
#
#   # IAM for CloudWatch and SSM
#   create_iam_role                = true
#   attach_ssm_policy              = true
#   attach_cloudwatch_agent_policy = true
#
#   # High-performance root volume
#   root_block_device = {
#     volume_type           = "gp3"
#     volume_size           = 100
#     iops                  = 16000
#     throughput            = 1000
#     encrypted             = true
#     delete_on_termination = false
#   }
#
#   # High-performance data volumes
#   additional_ebs_volumes = {
#     data = {
#       device_name = "/dev/sdf"
#       size        = 500
#       type        = "io2"
#       iops        = 32000
#       encrypted   = true
#     }
#     wal = {
#       device_name = "/dev/sdg"
#       size        = 200
#       type        = "io2"
#       iops        = 16000
#       encrypted   = true
#     }
#   }
#
#   # Protection settings
#   disable_api_termination = true
#   ebs_optimized           = true
#   enable_monitoring       = true
#
#   tags = {
#     Environment = "production"
#     Application = "database"
#     Role        = "primary"
#     Backup      = "required"
#   }
# }

# ========================================
# Example 14: NAT Instance (Alternative to NAT Gateway)
# ========================================

# module "nat_instance" {
#   source = "./"
#
#   name               = "nat-instance"
#   ami_id             = "ami-nat-instance"  # Use NAT-specific AMI
#   instance_type      = "t3.small"
#   subnet_id          = "subnet-public"
#
#   security_group_ids          = ["sg-nat"]
#   associate_public_ip_address = true
#   source_dest_check           = false  # Required for NAT
#
#   # Elastic IP for consistent NAT address
#   create_eip = true
#
#   # IAM for SSM access
#   create_iam_role   = true
#   attach_ssm_policy = true
#
#   tags = {
#     Environment = "production"
#     Type        = "nat-instance"
#   }
# }

# ========================================
# Example 15: Windows Server Instance
# ========================================

# module "windows_server" {
#   source = "./"
#
#   name          = "windows-app-server"
#   ami_id        = "ami-windows-2022"  # Windows Server 2022 AMI
#   instance_type = "t3.large"
#   subnet_id     = "subnet-12345678"
#
#   security_group_ids          = ["sg-windows"]
#   associate_public_ip_address = false
#
#   # Key pair for RDP password retrieval
#   create_key_pair       = true
#   store_key_pair_in_ssm = true
#
#   # IAM for SSM and Systems Manager
#   create_iam_role                = true
#   attach_ssm_policy              = true
#   attach_cloudwatch_agent_policy = true
#   additional_iam_policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess",
#   ]
#
#   # Windows-specific configuration
#   root_block_device = {
#     volume_type           = "gp3"
#     volume_size           = 100
#     encrypted             = true
#     delete_on_termination = true
#   }
#
#   # User data for Windows initialization
#   user_data = <<-EOF
#     <powershell>
#     # Install Chocolatey
#     Set-ExecutionPolicy Bypass -Scope Process -Force
#     [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
#     iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#
#     # Install common tools
#     choco install googlechrome -y
#     choco install 7zip -y
#     </powershell>
#   EOF
#
#   tags = {
#     Environment = "production"
#     OS          = "Windows"
#     Application = "app-server"
#   }
# }
