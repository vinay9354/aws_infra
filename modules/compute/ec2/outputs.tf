# ===================================
# Instance Outputs
# ===================================

output "instance_id" {
  description = "The ID of the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].spot_instance_id, null) : try(aws_instance.this[0].id, null)
}

output "instance_arn" {
  description = "The ARN of the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].arn, null) : try(aws_instance.this[0].arn, null)
}

output "instance_state" {
  description = "The state of the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].instance_state, null) : try(aws_instance.this[0].instance_state, null)
}

output "instance_type" {
  description = "The type of the instance"
  value       = try(aws_instance.this[0].instance_type, aws_spot_instance_request.this[0].instance_type, null)
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].private_ip, null) : try(aws_instance.this[0].private_ip, null)
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].public_ip, null) : try(aws_instance.this[0].public_ip, null)
}

output "private_dns" {
  description = "The private DNS name assigned to the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].private_dns, null) : try(aws_instance.this[0].private_dns, null)
}

output "public_dns" {
  description = "The public DNS name assigned to the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].public_dns, null) : try(aws_instance.this[0].public_dns, null)
}

output "availability_zone" {
  description = "The availability zone of the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].availability_zone, null) : try(aws_instance.this[0].availability_zone, null)
}

output "key_name" {
  description = "The key name of the instance"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].key_name, null) : try(aws_instance.this[0].key_name, null)
}

output "subnet_id" {
  description = "The VPC subnet ID"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].subnet_id, null) : try(aws_instance.this[0].subnet_id, null)
}

output "security_groups" {
  description = "The associated security groups"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].vpc_security_group_ids, []) : try(aws_instance.this[0].vpc_security_group_ids, [])
}

output "iam_instance_profile" {
  description = "The IAM instance profile"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].iam_instance_profile, null) : try(aws_instance.this[0].iam_instance_profile, null)
}

output "primary_network_interface_id" {
  description = "The ID of the instance's primary network interface"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].primary_network_interface_id, null) : try(aws_instance.this[0].primary_network_interface_id, null)
}

output "root_block_device" {
  description = "Root block device information"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].root_block_device, []) : try(aws_instance.this[0].root_block_device, [])
}

output "ebs_block_devices" {
  description = "EBS block device information"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].ebs_block_device, []) : try(aws_instance.this[0].ebs_block_device, [])
}

output "tags_all" {
  description = "A map of tags assigned to the instance, including those inherited from the provider default_tags"
  value       = var.use_spot_instance ? try(aws_spot_instance_request.this[0].tags_all, {}) : try(aws_instance.this[0].tags_all, {})
}

# ===================================
# Spot Instance Specific Outputs
# ===================================

output "spot_request_id" {
  description = "The ID of the Spot Instance request"
  value       = try(aws_spot_instance_request.this[0].id, null)
}

output "spot_request_state" {
  description = "The state of the Spot Instance request"
  value       = try(aws_spot_instance_request.this[0].spot_request_state, null)
}

output "spot_bid_status" {
  description = "The current bid status of the Spot Instance request"
  value       = try(aws_spot_instance_request.this[0].spot_bid_status, null)
}

output "spot_instance_id" {
  description = "The Instance ID (if the Spot Instance request has been fulfilled)"
  value       = try(aws_spot_instance_request.this[0].spot_instance_id, null)
}

# ===================================
# Elastic IP Outputs
# ===================================

output "eip_id" {
  description = "The ID of the Elastic IP"
  value       = try(aws_eip.this[0].id, null)
}

output "eip_public_ip" {
  description = "The Elastic IP address"
  value       = try(aws_eip.this[0].public_ip, null)
}

output "eip_allocation_id" {
  description = "The allocation ID of the Elastic IP"
  value       = try(aws_eip.this[0].allocation_id, null)
}

# ===================================
# EBS Volume Outputs
# ===================================

output "additional_ebs_volume_ids" {
  description = "Map of additional EBS volume IDs"
  value       = { for k, v in aws_ebs_volume.this : k => v.id }
}

output "additional_ebs_volume_arns" {
  description = "Map of additional EBS volume ARNs"
  value       = { for k, v in aws_ebs_volume.this : k => v.arn }
}

# ===================================
# IAM Role and Instance Profile Outputs
# ===================================

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = var.create_iam_role ? try(aws_iam_role.this[0].name, null) : (var.existing_iam_role_name != null ? var.existing_iam_role_name : null)
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = var.create_iam_role ? try(aws_iam_role.this[0].arn, null) : (var.existing_iam_role_name != null ? try(data.aws_iam_role.existing[0].arn, null) : null)
}

output "iam_role_id" {
  description = "The ID of the IAM role"
  value       = var.create_iam_role ? try(aws_iam_role.this[0].id, null) : null
}

output "iam_role_unique_id" {
  description = "The unique ID assigned by AWS to the IAM role"
  value       = var.create_iam_role ? try(aws_iam_role.this[0].unique_id, null) : null
}

output "iam_instance_profile_name" {
  description = "The name of the IAM instance profile"
  value       = var.create_iam_role ? try(aws_iam_instance_profile.this[0].name, null) : null
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM instance profile"
  value       = var.create_iam_role ? try(aws_iam_instance_profile.this[0].arn, null) : null
}

output "iam_instance_profile_id" {
  description = "The ID of the IAM instance profile"
  value       = var.create_iam_role ? try(aws_iam_instance_profile.this[0].id, null) : null
}

# ===================================
# Key Pair Outputs
# ===================================

output "key_pair_name" {
  description = "The name of the key pair"
  value       = var.create_key_pair ? try(aws_key_pair.this[0].key_name, null) : var.key_name
}

output "key_pair_id" {
  description = "The ID of the key pair"
  value       = var.create_key_pair ? try(aws_key_pair.this[0].id, null) : null
}

output "key_pair_arn" {
  description = "The ARN of the key pair"
  value       = var.create_key_pair ? try(aws_key_pair.this[0].arn, null) : null
}

output "key_pair_fingerprint" {
  description = "The MD5 public key fingerprint"
  value       = var.create_key_pair ? try(aws_key_pair.this[0].fingerprint, null) : null
}

output "private_key_ssm_parameter_name" {
  description = "The SSM parameter name where the private key is stored"
  value       = var.create_key_pair && var.store_key_pair_in_ssm ? try(aws_ssm_parameter.private_key[0].name, null) : null
}

output "public_key_ssm_parameter_name" {
  description = "The SSM parameter name where the public key is stored"
  value       = var.create_key_pair && var.store_key_pair_in_ssm ? try(aws_ssm_parameter.public_key[0].name, null) : null
}

output "private_key_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter storing the private key"
  value       = var.create_key_pair && var.store_key_pair_in_ssm ? try(aws_ssm_parameter.private_key[0].arn, null) : null
}

output "public_key_ssm_parameter_arn" {
  description = "The ARN of the SSM parameter storing the public key"
  value       = var.create_key_pair && var.store_key_pair_in_ssm ? try(aws_ssm_parameter.public_key[0].arn, null) : null
}

output "private_key_pem" {
  description = "The private key in PEM format (sensitive - only available when create_key_pair is true)"
  value       = var.create_key_pair ? try(tls_private_key.this[0].private_key_pem, null) : null
  sensitive   = true
}

output "public_key_openssh" {
  description = "The public key in OpenSSH format"
  value       = var.create_key_pair ? try(tls_private_key.this[0].public_key_openssh, null) : null
}

# ===================================
# Network Interface Outputs
# ===================================

output "created_network_interface_ids" {
  description = "Map of created network interface IDs"
  value       = { for k, v in aws_network_interface.this : k => v.id }
}

output "created_network_interface_private_ips" {
  description = "Map of created network interface private IPs"
  value       = { for k, v in aws_network_interface.this : k => v.private_ip }
}

output "created_network_interface_mac_addresses" {
  description = "Map of created network interface MAC addresses"
  value       = { for k, v in aws_network_interface.this : k => v.mac_address }
}

# ===================================
# Instance State Management Outputs
# ===================================

output "managed_instance_state" {
  description = "The managed state of the instance"
  value       = var.manage_instance_state ? try(aws_ec2_instance_state.this[0].state, null) : null
}
