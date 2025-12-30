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
# Security Group Outputs
# --------------------------------
output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    for k, v in module.security_group : k => v.security_group_id
  }
  sensitive = true
}

output "security_groups" {
  description = "Map of security group details (id, arn, name)"
  value = {
    for k, v in module.security_group : k => {
      id   = v.security_group_id
      arn  = v.security_group_arn
      name = v.security_group_name
    }
  }
  sensitive = true
}

# --------------------------------
# EC2 Instance Outputs
# --------------------------------
output "ec2_instance_ids" {
  description = "Map of EC2 instance IDs"
  value = {
    for k, v in module.ec2_instances : k => v.instance_id
  }
  sensitive = true
}

output "ec2_instances" {
  description = "Detailed information about EC2 instances"
  value = {
    for k, v in module.ec2_instances : k => {
      instance_id                  = v.instance_id
      instance_arn                 = v.instance_arn
      instance_state               = v.instance_state
      instance_type                = v.instance_type
      private_ip                   = v.private_ip
      public_ip                    = v.public_ip
      private_dns                  = v.private_dns
      public_dns                   = v.public_dns
      availability_zone            = v.availability_zone
      key_name                     = v.key_name
      subnet_id                    = v.subnet_id
      security_groups              = v.security_groups
      iam_instance_profile         = v.iam_instance_profile
      primary_network_interface_id = v.primary_network_interface_id
    }
  }
  sensitive = true
}

output "nat_instance_ip" {
  description = "Public IP address of the NAT instance"
  value       = try(module.ec2_instances["vinay-dev-infra-nat-instance"].public_ip, null)
  sensitive   = true
}

output "nat_instance_id" {
  description = "Instance ID of the NAT instance"
  value       = try(module.ec2_instances["vinay-dev-infra-nat-instance"].instance_id, null)
  sensitive   = true
}

output "nat_instance_primary_eni" {
  description = "Primary network interface ID of the NAT instance"
  value       = try(module.ec2_instances["vinay-dev-infra-nat-instance"].primary_network_interface_id, null)
  sensitive   = true
}

# --------------------------------
# EC2 Key Pair Outputs
# --------------------------------
output "key_pair_names" {
  description = "Map of key pair names created for EC2 instances"
  value = {
    for k, v in module.ec2_instances : k => v.key_pair_name if v.key_pair_name != null
  }
  sensitive = true
}

output "key_pair_ssm_parameters" {
  description = "Map of SSM parameter names storing private keys"
  value = {
    for k, v in module.ec2_instances : k => {
      private_key_param = v.private_key_ssm_parameter_name
      public_key_param  = v.public_key_ssm_parameter_name
    } if v.private_key_ssm_parameter_name != null
  }
  sensitive = true
}

# --------------------------------
# IAM Policy Outputs
# --------------------------------
output "iam_policy_arns" {
  description = "Map of IAM policy ARNs"
  value = {
    for k, v in module.iam_policies : k => v.arn
  }
  sensitive = true
}

output "iam_policies" {
  description = "Detailed information about IAM policies"
  value = {
    for k, v in module.iam_policies : k => {
      id          = v.id
      arn         = v.arn
      name        = v.name
      description = v.description
      path        = v.path
    }
  }
  sensitive = true
}

# --------------------------------
# IAM Role Outputs
# --------------------------------
output "iam_role_arns" {
  description = "Map of IAM role ARNs"
  value = {
    for k, v in module.iam_roles : k => v.role_arn
  }
  sensitive = true
}

output "iam_roles" {
  description = "Detailed information about IAM roles"
  value = {
    for k, v in module.iam_roles : k => {
      name                  = v.role_name
      arn                   = v.role_arn
      id                    = v.role_id
      unique_id             = v.role_unique_id
      instance_profile_name = v.instance_profile_name
      instance_profile_arn  = v.instance_profile_arn
      instance_profile_id   = v.instance_profile_id
    }
  }
  sensitive = true
}

# --------------------------------
# EKS Cluster Outputs
# --------------------------------
output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.dev_eks.cluster_name
  sensitive   = true
}

output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.dev_eks.cluster_id
  sensitive   = true
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the EKS cluster"
  value       = module.dev_eks.cluster_arn
  sensitive   = true
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the EKS cluster API server"
  value       = module.dev_eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.dev_eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = module.dev_eks.cluster_version
}

output "eks_cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.dev_eks.cluster_platform_version
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.dev_eks.cluster_status
}

output "eks_cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster"
  value       = module.dev_eks.cluster_primary_security_group_id
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster control plane"
  value       = module.dev_eks.cluster_security_group_id
  sensitive   = true
}

output "eks_node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.dev_eks.node_security_group_id
  sensitive   = true
}

# --------------------------------
# EKS OIDC Provider Outputs
# --------------------------------
output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.dev_eks.cluster_oidc_issuer_url
  sensitive   = true
}

output "eks_oidc_provider" {
  description = "The OpenID Connect identity provider (issuer URL without https://)"
  value       = module.dev_eks.oidc_provider
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for IRSA"
  value       = module.dev_eks.oidc_provider_arn
  sensitive   = true
}

# --------------------------------
# EKS IAM Role Outputs
# --------------------------------
output "eks_cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.dev_eks.cluster_iam_role_name
  sensitive   = true
}

output "eks_cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = module.dev_eks.cluster_iam_role_arn
  sensitive   = true
}

output "eks_managed_node_group_iam_role_arns" {
  description = "IAM role ARNs of the managed node groups"
  value       = module.dev_eks.managed_node_group_iam_role_arns
  sensitive   = true
}

output "eks_self_managed_node_group_iam_role_arns" {
  description = "IAM role ARNs of the self-managed node groups"
  value       = module.dev_eks.self_managed_node_group_iam_role_arns
  sensitive   = true
}

# --------------------------------
# EKS Node Groups Outputs
# --------------------------------
output "eks_managed_node_groups" {
  description = "Map of outputs for all managed node groups created"
  value       = module.dev_eks.managed_node_groups
  sensitive   = true
}

output "eks_managed_node_groups_asg_names" {
  description = "List of autoscaling group names created by managed node groups"
  value       = module.dev_eks.managed_node_groups_autoscaling_group_names
  sensitive   = true
}

output "eks_self_managed_node_groups" {
  description = "Map of outputs for all self-managed node groups created"
  value       = module.dev_eks.self_managed_node_groups
  sensitive   = true
}

output "eks_fargate_profiles" {
  description = "Map of outputs for all Fargate profiles created"
  value       = module.dev_eks.fargate_profiles
  sensitive   = true
}

# --------------------------------
# EKS KMS and CloudWatch Outputs
# --------------------------------
output "eks_kms_key_arn" {
  description = "The ARN of the KMS key used for cluster encryption"
  value       = module.dev_eks.kms_key_arn
  sensitive   = true
}

output "eks_cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch log group created for EKS cluster"
  value       = module.dev_eks.cloudwatch_log_group_arn
  sensitive   = true
}

# --------------------------------
# EKS Configuration Outputs
# --------------------------------
output "eks_kubeconfig_command" {
  description = "Command to update local kubeconfig"
  value       = module.dev_eks.kubeconfig_command
}

output "eks_cluster_info" {
  description = "Comprehensive EKS cluster information"
  value = {
    cluster_name         = module.dev_eks.cluster_name
    cluster_endpoint     = module.dev_eks.cluster_endpoint
    cluster_version      = module.dev_eks.cluster_version
    oidc_provider        = module.dev_eks.oidc_provider
    cluster_iam_role_arn = module.dev_eks.cluster_iam_role_arn
    kubeconfig_command   = module.dev_eks.kubeconfig_command
  }
  sensitive = true
}
