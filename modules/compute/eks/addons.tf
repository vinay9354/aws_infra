# Split EKS managed addons into:
#  - a dedicated resource for the Amazon VPC CNI (created immediately after the cluster)
#  - a separate resource for all other addons (created after node groups / ASG exist)
#
# This avoids the circular ordering problem:
#  - nodes must wait for the vpc-cni addon to be ACTIVE so kubelet/aws-node can bring up pod networking
#  - other addons (coredns, kube-proxy, ebs-csi-driver, etc.) should wait until nodes exist and are able to schedule pods

# -------------------------------------------------------------------
# VPC CNI addon: created before node groups (no depends_on on node group)
# -------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  for_each = { for k, v in var.cluster_addons : k => v if k == "vpc-cni" }

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = lookup(each.value, "addon_version", null)

  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  preserve = lookup(each.value, "preserve", null)

  dynamic "timeouts" {
    for_each = lookup(each.value, "timeouts", null) != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = var.tags

  # Intentionally do not depend on node groups: the VPC CNI must be present/ACTIVE
  # before nodes can fully join and become Ready.
}

# -------------------------------------------------------------------
# All other addons: created after node groups (so pods can schedule)
# -------------------------------------------------------------------
resource "aws_eks_addon" "others" {
  for_each = { for k, v in var.cluster_addons : k => v if k != "vpc-cni" }

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = lookup(each.value, "addon_version", null)

  resolve_conflicts_on_create = lookup(each.value, "resolve_conflicts_on_create", null)
  resolve_conflicts_on_update = lookup(each.value, "resolve_conflicts_on_update", null)
  configuration_values        = lookup(each.value, "configuration_values", null)
  service_account_role_arn    = lookup(each.value, "service_account_role_arn", null)

  preserve = lookup(each.value, "preserve", null)

  dynamic "timeouts" {
    for_each = lookup(each.value, "timeouts", null) != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  tags = var.tags

  # Ensure node groups and autoscaling groups exist before creating other addons,
  # so pods like CoreDNS can be scheduled and become Ready.
  depends_on = [
    aws_eks_node_group.this,
    aws_autoscaling_group.this,
  ]
}
