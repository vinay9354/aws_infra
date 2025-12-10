# Data source to get existing IAM role if specified
data "aws_iam_role" "existing" {
  count = var.create_instance && !var.create_iam_role && var.existing_iam_role_name != null ? 1 : 0
  name  = var.existing_iam_role_name
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "this" {
  count = var.create_instance && var.create_iam_role ? 1 : 0

  name = "${var.name}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-role"
    }
  )
}

# Attach SSM Managed Instance Core Policy (default)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  count = var.create_instance && var.create_iam_role && var.attach_ssm_policy ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy (default)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = var.create_instance && var.create_iam_role && var.attach_cloudwatch_agent_policy ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach additional custom policies
resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_instance && var.create_iam_role ? toset(var.additional_iam_policy_arns) : []

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_instance && var.create_iam_role ? 1 : 0

  name = "${var.name}-instance-profile"
  role = aws_iam_role.this[0].name

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-instance-profile"
    }
  )
}

# Generate TLS private key for key pair
resource "tls_private_key" "this" {
  count = var.create_instance && var.create_key_pair ? 1 : 0

  algorithm = var.key_pair_algorithm
  rsa_bits  = var.key_pair_algorithm == "RSA" ? var.key_pair_rsa_bits : null
}

# Create Key Pair
resource "aws_key_pair" "this" {
  count = var.create_instance && var.create_key_pair ? 1 : 0

  key_name   = var.key_pair_name != null ? var.key_pair_name : "${var.name}-key"
  public_key = tls_private_key.this[0].public_key_openssh

  tags = merge(
    var.tags,
    {
      Name = var.key_pair_name != null ? var.key_pair_name : "${var.name}-key"
    }
  )
}

# Store Private Key in SSM Parameter Store
resource "aws_ssm_parameter" "private_key" {
  count = var.create_instance && var.create_key_pair && var.store_key_pair_in_ssm ? 1 : 0

  name        = var.private_key_ssm_parameter_name != null ? var.private_key_ssm_parameter_name : "/${var.name}/ec2/private-key"
  description = "Private key for EC2 instance ${var.name}"
  type        = "SecureString"
  value       = tls_private_key.this[0].private_key_pem

  tags = merge(
    var.tags,
    {
      Name     = "${var.name}-private-key"
      Instance = var.name
    }
  )
}

# Store Public Key in SSM Parameter Store
resource "aws_ssm_parameter" "public_key" {
  count = var.create_instance && var.create_key_pair && var.store_key_pair_in_ssm ? 1 : 0

  name        = var.public_key_ssm_parameter_name != null ? var.public_key_ssm_parameter_name : "/${var.name}/ec2/public-key"
  description = "Public key for EC2 instance ${var.name}"
  type        = "SecureString"
  value       = tls_private_key.this[0].public_key_openssh

  tags = merge(
    var.tags,
    {
      Name     = "${var.name}-public-key"
      Instance = var.name
    }
  )
}

# Create Network Interfaces if needed
resource "aws_network_interface" "this" {
  for_each = var.create_instance && var.create_network_interfaces ? var.network_interface_configs : {}

  subnet_id         = each.value.subnet_id
  security_groups   = try(each.value.security_group_ids, [])
  private_ips       = try(each.value.private_ips, [])
  private_ip        = try(each.value.private_ip, null)
  source_dest_check = try(each.value.source_dest_check, true)
  description       = try(each.value.description, "Network interface for ${var.name}")

  attachment {
    instance     = aws_instance.this[0].id
    device_index = each.value.device_index
  }

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = "${var.name}-eni-${each.key}"
    }
  )

  depends_on = [aws_instance.this]
}

# Spot Instance Request (alternative to regular instance)
resource "aws_spot_instance_request" "this" {
  count = var.create_instance && var.use_spot_instance ? 1 : 0

  ami                                  = var.ami_id
  instance_type                        = var.instance_type
  key_name                             = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.security_group_ids
  iam_instance_profile                 = var.create_iam_role ? aws_iam_instance_profile.this[0].name : (var.existing_iam_role_name != null ? data.aws_iam_role.existing[0].name : var.iam_instance_profile)
  associate_public_ip_address          = var.associate_public_ip_address
  user_data                            = var.user_data
  user_data_base64                     = var.user_data_base64
  monitoring                           = var.enable_monitoring
  ebs_optimized                        = var.ebs_optimized
  source_dest_check                    = var.source_dest_check
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }
  availability_zone = var.availability_zone

  # Spot specific settings
  spot_price                     = var.spot_price
  wait_for_fulfillment           = var.spot_wait_for_fulfillment
  spot_type                      = var.spot_type
  instance_interruption_behavior = var.spot_instance_interruption_behavior
  valid_until                    = var.spot_valid_until

  dynamic "root_block_device" {
    for_each = var.root_block_device != null ? [var.root_block_device] : []
    content {
      volume_type           = try(root_block_device.value.volume_type, "gp3")
      volume_size           = try(root_block_device.value.volume_size, 8)
      iops                  = try(root_block_device.value.iops, null)
      throughput            = try(root_block_device.value.throughput, null)
      delete_on_termination = try(root_block_device.value.delete_on_termination, true)
      encrypted             = try(root_block_device.value.encrypted, true)
      kms_key_id            = try(root_block_device.value.kms_key_id, null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = try(ebs_block_device.value.volume_type, "gp3")
      volume_size           = try(ebs_block_device.value.volume_size, 10)
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, true)
      encrypted             = try(ebs_block_device.value.encrypted, true)
      kms_key_id            = try(ebs_block_device.value.kms_key_id, null)
      snapshot_id           = try(ebs_block_device.value.snapshot_id, null)

    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_devices
    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = network_interface.value.network_interface_id
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []
    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, "disabled")
    }
  }

  dynamic "credit_specification" {
    for_each = var.cpu_credits != null ? [var.cpu_credits] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  volume_tags = merge(
    var.tags,
    var.volume_tags,
    {
      Name = "${var.name}-volume"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      user_data_base64,
      associate_public_ip_address
    ]
  }
}

# Regular EC2 Instance (on-demand)
resource "aws_instance" "this" {
  count = var.create_instance && !var.use_spot_instance ? 1 : 0

  ami                                  = var.ami_id
  instance_type                        = var.instance_type
  key_name                             = var.create_key_pair ? aws_key_pair.this[0].key_name : var.key_name
  subnet_id                            = var.subnet_id
  vpc_security_group_ids               = var.security_group_ids
  iam_instance_profile                 = var.create_iam_role ? aws_iam_instance_profile.this[0].name : (var.existing_iam_role_name != null ? data.aws_iam_role.existing[0].name : var.iam_instance_profile)
  associate_public_ip_address          = var.associate_public_ip_address
  user_data                            = var.user_data
  user_data_base64                     = var.user_data_base64
  monitoring                           = var.enable_monitoring
  ebs_optimized                        = var.ebs_optimized
  source_dest_check                    = var.source_dest_check
  disable_api_termination              = var.disable_api_termination
  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior
  placement_group                      = var.placement_group
  tenancy                              = var.tenancy
  host_id                              = var.host_id
  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.cpu_threads_per_core
  }
  availability_zone = var.availability_zone

  dynamic "root_block_device" {
    for_each = var.root_block_device != null ? [var.root_block_device] : []
    content {
      volume_type           = try(root_block_device.value.volume_type, "gp3")
      volume_size           = try(root_block_device.value.volume_size, 8)
      iops                  = try(root_block_device.value.iops, null)
      throughput            = try(root_block_device.value.throughput, null)
      delete_on_termination = try(root_block_device.value.delete_on_termination, true)
      encrypted             = try(root_block_device.value.encrypted, true)
      kms_key_id            = try(root_block_device.value.kms_key_id, null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = var.ebs_block_devices
    content {
      device_name           = ebs_block_device.value.device_name
      volume_type           = try(ebs_block_device.value.volume_type, "gp3")
      volume_size           = try(ebs_block_device.value.volume_size, 10)
      iops                  = try(ebs_block_device.value.iops, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, true)
      encrypted             = try(ebs_block_device.value.encrypted, true)
      kms_key_id            = try(ebs_block_device.value.kms_key_id, null)
      snapshot_id           = try(ebs_block_device.value.snapshot_id, null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = var.ephemeral_block_devices
    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
    }
  }

  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = network_interface.value.network_interface_id
      delete_on_termination = try(network_interface.value.delete_on_termination, false)
    }
  }

  dynamic "metadata_options" {
    for_each = length(var.metadata_options) > 0 ? [var.metadata_options] : []
    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, "enabled")
      http_tokens                 = try(metadata_options.value.http_tokens, "required")
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, 1)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, "disabled")
    }
  }

  dynamic "credit_specification" {
    for_each = var.cpu_credits != null ? [var.cpu_credits] : []
    content {
      cpu_credits = credit_specification.value
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )

  volume_tags = merge(
    var.tags,
    var.volume_tags
    ,
    {
      Name = "${var.name}-volume"
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data,
      user_data_base64,
      associate_public_ip_address
    ]
  }
}

# Instance State Management
resource "aws_ec2_instance_state" "this" {
  count = var.create_instance && var.manage_instance_state ? 1 : 0

  instance_id = var.use_spot_instance ? aws_spot_instance_request.this[0].spot_instance_id : aws_instance.this[0].id
  state       = var.instance_state

  force = var.force_instance_state_change

  depends_on = [
    aws_instance.this,
    aws_spot_instance_request.this
  ]
}

# Elastic IP
resource "aws_eip" "this" {
  count = var.create_instance && var.create_eip ? 1 : 0

  domain   = "vpc"
  instance = var.use_spot_instance ? aws_spot_instance_request.this[0].spot_instance_id : aws_instance.this[0].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eip"
    }
  )

  depends_on = [aws_instance.this, aws_spot_instance_request.this]
}

# Additional EBS Volumes
resource "aws_ebs_volume" "this" {
  for_each = var.create_instance ? var.additional_ebs_volumes : {}

  availability_zone = var.use_spot_instance ? aws_spot_instance_request.this[0].availability_zone : aws_instance.this[0].availability_zone
  size              = each.value.size
  type              = try(each.value.type, "gp3")
  iops              = try(each.value.iops, null)
  throughput        = try(each.value.throughput, null)
  encrypted         = try(each.value.encrypted, true)
  kms_key_id        = try(each.value.kms_key_id, null)
  snapshot_id       = try(each.value.snapshot_id, null)

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = "${var.name}-${each.key}"
    }
  )
}

resource "aws_volume_attachment" "this" {
  for_each = var.create_instance ? var.additional_ebs_volumes : {}

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.this[each.key].id
  instance_id = var.use_spot_instance ? aws_spot_instance_request.this[0].spot_instance_id : aws_instance.this[0].id

  force_detach = try(each.value.force_detach, false)
  skip_destroy = try(each.value.skip_destroy, false)
}

# Attach existing network interfaces
resource "aws_network_interface_attachment" "existing" {
  for_each = var.create_instance && !var.create_network_interfaces ? var.additional_network_interfaces : {}

  instance_id          = var.use_spot_instance ? aws_spot_instance_request.this[0].spot_instance_id : aws_instance.this[0].id
  network_interface_id = each.value.network_interface_id
  device_index         = each.value.device_index
}
