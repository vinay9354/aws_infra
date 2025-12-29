#--------------
# Outputs
# -------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
  sensitive   = true
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
  sensitive   = true
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value = {
    for k, v in module.public_subnets : k => v.subnet_id
  }
  sensitive = true
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs"
  value = {
    for k, v in module.private_subnets : k => v.subnet_id
  }
  sensitive = true
}

output "public_route_table_ids" {
  description = "Map of public subnet route table IDs"
  value = {
    for k, v in module.public_subnets : k => v.route_table_id
  }
  sensitive = true
}

output "private_route_table_ids" {
  description = "Map of private subnet route table IDs"
  value = {
    for k, v in module.private_subnets : k => v.route_table_id
  }
  sensitive = true
}

# --------------------------------
# EKS Cluster Outputs
# --------------------------------

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
  sensitive   = true
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
  sensitive   = true
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
  sensitive   = true
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint URL"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
  sensitive   = true
}

output "eks_cluster_platform_version" {
  description = "EKS cluster platform version"
  value       = module.eks.cluster_platform_version
  sensitive   = true
}

output "eks_cluster_certificate_authority" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
  sensitive   = true
}

output "eks_cluster_iam_role_arn" {
  description = "EKS cluster IAM role ARN"
  value       = module.eks.cluster_iam_role_arn
  sensitive   = true
}

output "eks_managed_node_groups" {
  description = "Map of managed node group resources"
  value = {
    for k, v in module.eks.managed_node_groups : k => {
      id            = v.id
      arn           = v.arn
      status        = v.status
      capacity_type = v.capacity_type
    }
  }
  sensitive = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS (for IRSA)"
  value       = try(module.eks.oidc_provider_arn, null)
  sensitive   = true
}

output "eks_irsa_oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS (for IRSA)"
  value       = try(module.eks.oidc_provider_url, null)
  sensitive   = true
}

output "eks_kms_key_id" {
  description = "The KMS key ID used for cluster encryption"
  value       = try(module.eks.kms_key_id, null)
  sensitive   = true
}

output "eks_cluster_addons" {
  description = "Map of installed cluster add-ons"
  value = {
    for k, v in module.eks.cluster_addons : k => {
      addon_version = v.addon_version
      created_at    = v.created_at
      modified_at   = v.modified_at
    }
  }
  sensitive = true
}

output "eks_connect_config" {
  description = "Configuration needed to connect to the EKS cluster"
  value = {
    cluster_name          = module.eks.cluster_name
    cluster_endpoint      = module.eks.cluster_endpoint
    certificate_authority = module.eks.cluster_certificate_authority_data
    region                = data.aws_region.current.region
  }
  sensitive = true
}