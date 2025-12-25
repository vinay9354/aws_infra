resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = length(var.control_plane_subnet_ids) > 0 ? var.control_plane_subnet_ids : var.subnet_ids
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.cluster_endpoint_private_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids = concat(
      var.create_cluster_security_group ? [aws_security_group.cluster[0].id] : [var.cluster_security_group_id],
      var.cluster_additional_security_group_ids
    )
  }
  kubernetes_network_config {
    ip_family         = var.cluster_ip_family
    service_ipv4_cidr = var.cluster_ip_family == "ipv6" ? null : var.cluster_service_ipv4_cidr
    service_ipv6_cidr = var.cluster_ip_family == "ipv6" ? var.cluster_service_ipv6_cidr : null
  }
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # Envelope Encryption
  dynamic "encryption_config" {
    for_each = local.kms_key_arn != null ? [1] : []
    content {
      provider {
        key_arn = local.kms_key_arn
      }
      resources = ["secrets"]
    }
  }

  # Access Entries (Replacing aws-auth)
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP" # Support both while migrating
    bootstrap_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  }
  tags = var.tags
  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_vpc_controller,
    aws_cloudwatch_log_group.this
  ]
  lifecycle {
    ignore_changes = []
    precondition {
      condition     = var.create_cluster_security_group || length(var.cluster_security_group_id) > 0
      error_message = "cluster_security_group_id must be provided when create_cluster_security_group is false."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Access Entries (New AWS Standard for K8s Auth)
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_access_entry" "this" {
  for_each          = var.access_entries
  cluster_name      = aws_eks_cluster.this.name
  principal_arn     = each.value.principal_arn
  kubernetes_groups = each.value.kubernetes_groups
  type              = each.value.type
  user_name         = each.value.user_name
  tags              = var.tags
}

# Re-implementing Access Policy Association to be more robust

resource "aws_eks_access_policy_association" "access_policy" {
  for_each = {
    for association in flatten([
      for entry_key, entry_val in var.access_entries : [
        for policy_key, policy_val in entry_val.policy_associations : {
          key           = "${entry_key}-${policy_key}"
          principal_arn = entry_val.principal_arn
          policy_arn    = policy_val.policy_arn
          access_scope  = policy_val.access_scope
        }
      ]
    ]) : association.key => association
  }

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn
  access_scope {
    type       = each.value.access_scope.type
    namespaces = each.value.access_scope.namespaces
  }
}
