# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Self-Managed Nodes
# ---------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "self_managed_assume_role" {
  count = length(var.self_managed_node_groups) > 0 ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "self_managed" {
  for_each = { for k, v in var.self_managed_node_groups : k => v if v.create_iam_role }

  name               = "${var.cluster_name}-${each.key}-self-managed-role"
  assume_role_policy = data.aws_iam_policy_document.self_managed_assume_role[0].json
  tags               = merge(var.tags, each.value.tags)
}

resource "aws_iam_role_policy_attachment" "self_managed_worker_policy" {
  for_each   = { for k, v in var.self_managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.self_managed[each.key].name
}

resource "aws_iam_role_policy_attachment" "self_managed_cni_policy" {
  for_each   = { for k, v in var.self_managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.self_managed[each.key].name
}

resource "aws_iam_role_policy_attachment" "self_managed_registry_policy" {
  for_each   = { for k, v in var.self_managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.self_managed[each.key].name
}

resource "aws_iam_role_policy_attachment" "self_managed_additional_policies" {
  for_each = {
    for pair in flatten([
      for group_key, group_val in var.self_managed_node_groups : [
        for policy_name, policy_arn in group_val.iam_role_additional_policies : {
          group_key   = group_key
          policy_name = policy_name
          policy_arn  = policy_arn
        }
      ] if group_val.create_iam_role
    ]) : "${pair.group_key}-${pair.policy_name}" => pair
  }

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.self_managed[each.value.group_key].name
}

resource "aws_iam_instance_profile" "self_managed_node_group" {
  for_each = var.self_managed_node_groups

  name = "${var.cluster_name}-${each.key}-profile"
  role = each.value.create_iam_role ? aws_iam_role.self_managed[each.key].name : split("/", each.value.iam_role_arn)[1] # Extract role name from ARN
  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Launch Template for Self-Managed Node Groups
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "self_managed" {
  for_each = var.self_managed_node_groups

  name_prefix = "${var.cluster_name}-${each.key}-self-"

  # Logic: Use provided AMI ID -> Fallback to Windows Optimized -> Fallback to AL2023 Optimized
  image_id = each.value.ami_id != null ? each.value.ami_id : (each.value.platform == "windows" ? local.default_windows_ami_id : local.default_linux_ami_id)

  instance_type = each.value.instance_type

  user_data = each.value.platform == "windows" ? base64encode(templatefile("${path.module}/templates/windows_user_data.tpl", { cluster_name = var.cluster_name
    cluster_endpoint     = aws_eks_cluster.this.endpoint
    cluster_auth_base64  = aws_eks_cluster.this.certificate_authority[0].data
    bootstrap_extra_args = each.value.bootstrap_extra_args
    })) : base64encode(templatefile("${path.module}/templates/al2023_user_data.tpl", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = aws_eks_cluster.this.endpoint
    cluster_auth_base64 = aws_eks_cluster.this.certificate_authority[0].data
    # Note: For AL2023, bootstrap_extra_args should be valid YAML content for Kubelet config if provided
    bootstrap_extra_args = each.value.bootstrap_extra_args
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.self_managed_node_group[each.key].name
  }

  key_name = each.value.key_name

  vpc_security_group_ids = [aws_security_group.node.id, var.create_cluster_security_group ? aws_security_group.cluster[0].id : var.cluster_security_group_id]



  block_device_mappings {

    device_name = "/dev/xvda"

    ebs {

      volume_size = 20 # Default

      volume_type = "gp3"

      encrypted = true

      kms_key_id = local.kms_key_arn

    }

  }



  # Enforce IMDSv2 for Security

  metadata_options {

    http_endpoint = "enabled"

    http_tokens = "required"

    http_put_response_hop_limit = 2

    instance_metadata_tags = "enabled"

  }



  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.tags,
      each.value.tags,
      {
        "Name"                                      = "${var.cluster_name}-${each.key}-self-managed"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      }
    )
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# Auto Scaling Group (Self-Managed)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  for_each = var.self_managed_node_groups

  name_prefix = "${var.cluster_name}-${each.key}-"

  desired_capacity = each.value.desired_capacity
  max_size         = each.value.max_size
  min_size         = each.value.min_size

  vpc_zone_identifier = length(each.value.subnet_ids != null ? each.value.subnet_ids : []) > 0 ? each.value.subnet_ids : (length(var.node_group_subnet_ids) > 0 ? var.node_group_subnet_ids : var.subnet_ids)

  launch_template {
    id      = aws_launch_template.self_managed[each.key].id
    version = "$Latest"
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = merge(var.tags, each.value.tags)
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
