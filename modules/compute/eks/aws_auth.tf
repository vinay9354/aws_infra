# ---------------------------------------------------------------------------------------------------------------------
# AWS Auth ConfigMap (Legacy)
# ---------------------------------------------------------------------------------------------------------------------
# IMPORTANT: To use this feature (`manage_aws_auth_configmap = true`), the caller MUST configure the `kubernetes` provider.
# The provider should be configured to point to this cluster (endpoint, ca_certificate, token).
# Example:
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

locals {
  # Merge the roles
  aws_auth_roles = concat(
    # Managed Node Group Roles
    [
      for k, v in var.managed_node_groups : {
        rolearn  = v.create_iam_role ? aws_iam_role.managed_node_group[k].arn : v.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ],

    # Self-Managed Node Group Roles
    [
      for k, v in var.self_managed_node_groups : {
        rolearn  = v.create_iam_role ? aws_iam_role.self_managed[k].arn : v.iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ],

    # Add Fargate Pod Execution Role if created
    length(var.fargate_profiles) > 0 ? [{
      rolearn  = aws_iam_role.fargate[0].arn
      username = "system:node:{{SessionName}}"
      groups   = ["system:bootstrappers", "system:nodes", "system:node-proxier"]
    }] : [],

    # Add User provided roles
    var.aws_auth_roles
  )
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  count = var.manage_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles    = yamlencode(local.aws_auth_roles)
    mapUsers    = yamlencode(var.aws_auth_users)
    mapAccounts = yamlencode(var.aws_auth_accounts)
  }

  force = true

  # Ensure the cluster is ready before attempting to write
  depends_on = [aws_eks_cluster.this]
}
