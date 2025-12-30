# ---------------------------------------------------------------------------------------------------------------------
# Cluster Details Outputs
# These outputs provide fundamental information about the created EKS cluster.
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = aws_eks_cluster.this.platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = aws_eks_cluster.this.status
}

# ---------------------------------------------------------------------------------------------------------------------
# Security & Networking Outputs
# Outputs related to security groups and network configuration.
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = var.create_cluster_security_group ? aws_security_group.cluster[0].id : var.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = aws_security_group.node.id
}

# ---------------------------------------------------------------------------------------------------------------------
# Authentication & Authorization Outputs
# Outputs for OIDC provider and related IAM configurations.
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without https://)"
  value       = var.enable_irsa ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : null
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider if `enable_irsa` is true"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.oidc_provider[0].arn : null
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Roles Outputs
# ARNs and names of IAM roles created for the cluster and node groups.
# ---------------------------------------------------------------------------------------------------------------------

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = aws_iam_role.cluster.name
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "managed_node_group_iam_role_arns" {
  description = "IAM role ARNs of the managed node groups"
  value       = { for k, v in aws_iam_role.managed_node_group : k => v.arn }
}

output "self_managed_node_group_iam_role_arns" {
  description = "IAM role ARNs of the self-managed node groups"
  value       = { for k, v in aws_iam_role.self_managed : k => v.arn }
}

# ---------------------------------------------------------------------------------------------------------------------
# Compute Resource Outputs
# Details about managed, self-managed node groups and Fargate profiles.
# ---------------------------------------------------------------------------------------------------------------------

output "managed_node_groups" {
  description = "Map of outputs for all managed node groups created"
  value       = aws_eks_node_group.this
}

output "managed_node_groups_autoscaling_group_names" {
  description = "List of autoscaling group names created by managed node groups"
  value = flatten([
    for group in aws_eks_node_group.this : [
      for asg in group.resources[0].autoscaling_groups : asg.name
    ]
  ])
}

output "self_managed_node_groups" {
  description = "Map of outputs for all self-managed node groups created"
  value       = aws_autoscaling_group.this
}

output "fargate_profiles" {
  description = "Map of outputs for all Fargate profiles created"
  value       = aws_eks_fargate_profile.this
}

# ---------------------------------------------------------------------------------------------------------------------
# Logging & Encryption Outputs
# Information about CloudWatch log groups and KMS keys.
# ---------------------------------------------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "The ARN of the KMS key used for cluster encryption"
  value       = local.kms_key_arn
}

output "cloudwatch_log_group_arn" {
  description = "Arn of cloudwatch log group created"
  value       = aws_cloudwatch_log_group.this.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Helper Outputs
# Utility outputs for interacting with the cluster.
# ---------------------------------------------------------------------------------------------------------------------

output "kubeconfig_command" {
  description = "Command to update local kubeconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${data.aws_region.current.region}"
}
