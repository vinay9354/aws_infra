# ---------------------------------------------------------------------------------------------------------------------
# AWS Auth ConfigMap (Legacy)
# Manages the `aws-auth` ConfigMap for granting IAM principals access to the Kubernetes cluster.
# IMPORTANT: This is a legacy mechanism. For modern EKS access management, use Access Entries.
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
  # Consolidate all roles to be mapped in the aws-auth ConfigMap.
  # This includes roles for managed node groups, self-managed node groups,
  # Fargate pod execution roles, and any user-provided roles.
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

    # Add Fargate Pod Execution Role if created and Fargate profiles exist
    length(var.fargate_profiles) > 0 ? [{
      rolearn  = aws_iam_role.fargate[0].arn
      username = "system:node:{{SessionName}}" # Fargate uses SessionName for username
      groups   = ["system:bootstrappers", "system:nodes", "system:node-proxier"]
    }] : [],

    # Add any user-defined roles from the input variable
    var.aws_auth_roles
  )
}

# Resource to create and manage the kubernetes `aws-auth` ConfigMap
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

  force = true # Force update if the content changes

  # Ensure the EKS cluster is fully ready before attempting to write the ConfigMap
  depends_on = [aws_eks_cluster.this]
}