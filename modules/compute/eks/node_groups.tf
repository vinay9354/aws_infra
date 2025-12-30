# ---------------------------------------------------------------------------------------------------------------------
# Launch Templates (Optional but Recommended)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "this" {

  for_each    = { for k, v in var.managed_node_groups : k => v if v.create_launch_template }
  name_prefix = "${var.cluster_name}-${each.key}-"
  description = "Launch template for EKS managed node group ${each.key}"

  # Fallback to default AL2 AMI if no custom AMI provided.

  # This prevents passing 'null' which causes API errors, and ensures a valid AMI is always present in the LT.

  image_id               = lookup(each.value, "ami_id", null)
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = each.value.disk_size
      volume_type = "gp3"
      encrypted   = true
      # kms_key_id  = var.kms_key_arn # Optional: Use specific key if provided
    }
  }

  # If user provides custom block devices, we could merge them here,
  # but for simplicity in this "production base", we default to secure gp3.

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      each.value.tags,
      {
        "Name" = "${var.cluster_name}-${each.key}"
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.tags,
      each.value.tags,
      {
        "Name" = "${var.cluster_name}-${each.key}"
      }
    )
  }

  # Setup for Metadata Options (Security Best Practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 2
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Managed Node Groups
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_node_group" "this" {
  for_each = var.managed_node_groups

  cluster_name           = aws_eks_cluster.this.name
  node_group_name        = each.value.use_name_prefix ? null : "${var.cluster_name}-${each.key}"
  node_group_name_prefix = each.value.use_name_prefix ? (length("${var.cluster_name}-${each.key}") > 37 ? substr("${var.cluster_name}-${each.key}", 0, 37) : "${var.cluster_name}-${each.key}") : null

  node_role_arn = each.value.create_iam_role ? aws_iam_role.managed_node_group[each.key].arn : each.value.iam_role_arn
  subnet_ids    = length(each.value.subnet_ids != null ? each.value.subnet_ids : []) > 0 ? each.value.subnet_ids : (length(var.node_group_subnet_ids) > 0 ? var.node_group_subnet_ids : var.subnet_ids)

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Update Configuration
  dynamic "update_config" {
    for_each = each.value.update_config != null ? [each.value.update_config] : []
    content {
      max_unavailable            = update_config.value.max_unavailable
      max_unavailable_percentage = update_config.value.max_unavailable_percentage
    }
  }

  ami_type       = (each.value.create_launch_template && each.value.ami_id != null) ? "CUSTOM" : each.value.ami_type
  capacity_type  = each.value.capacity_type
  instance_types = each.value.instance_types

  # Configuration via Launch Template
  dynamic "launch_template" {
    for_each = each.value.create_launch_template ? [1] : []
    content {
      id      = aws_launch_template.this[each.key].id
      version = aws_launch_template.this[each.key].latest_version
    }
  }

  # Labels
  labels = each.value.labels

  # Taints
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )

  depends_on = [
    aws_iam_role_policy_attachment.managed_node_worker_policy,
    aws_iam_role_policy_attachment.managed_node_cni_policy,
    aws_iam_role_policy_attachment.managed_node_registry_policy,
    # Ensure VPC CNI addon is present before creating node group (if the addon is declared)
    # This reference is safe when `vpc-cni` exists in the `var.cluster_addons` map because we create
    # a dedicated `aws_eks_addon.vpc_cni` for that key. If `vpc-cni` is not present in the map,
    # Terraform will error if referenced — in that case apply in two phases instead.
    aws_eks_addon.vpc_cni["vpc-cni"],
  ]

  # Ignore changes to scaling config if autoscaler is expected to manage it
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
