# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for EKS Cluster Control Plane
# Defines the IAM role that the EKS control plane uses to manage AWS resources.
# ---------------------------------------------------------------------------------------------------------------------

# Policy document for the EKS cluster to assume its role
data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# IAM Role for the EKS cluster control plane
resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = var.tags
}

# Attach AmazonEKSClusterPolicy for core EKS cluster functionality
resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Attach AmazonEKSVPCResourceController for managing VPC resources like ENIs and Load Balancers
resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Roles for Managed Node Groups (Dedicated per Group)
# Defines IAM roles for each managed node group to grant necessary permissions to EC2 instances.
# ---------------------------------------------------------------------------------------------------------------------

# Policy document for EC2 instances to assume their node roles
data "aws_iam_policy_document" "node_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# IAM Role for each managed node group
resource "aws_iam_role" "managed_node_group" {
  for_each           = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  name               = "${var.cluster_name}-${each.key}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = merge(var.tags, each.value.tags)
}

# Attach AmazonEKSWorkerNodePolicy for general worker node permissions
resource "aws_iam_role_policy_attachment" "managed_node_worker_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_node_group[each.key].name
}

# Attach AmazonEKS_CNI_Policy for Kubernetes CNI (Container Network Interface)
resource "aws_iam_role_policy_attachment" "managed_node_cni_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_node_group[each.key].name
}

# Attach AmazonEC2ContainerRegistryReadOnly for pulling container images from ECR
resource "aws_iam_role_policy_attachment" "managed_node_registry_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_node_group[each.key].name
}

# Attach any additional policies specified for the managed node group
resource "aws_iam_role_policy_attachment" "managed_node_additional_policies" {
  for_each = {
    for pair in flatten([
      for group_key, group_val in var.managed_node_groups : [
        for policy_name, policy_arn in group_val.iam_role_additional_policies : {
          group_key   = group_key
          policy_name = policy_name
          policy_arn  = policy_arn
        }
      ] if group_val.create_iam_role # Only attach if a role is being created by the module
    ]) : "${pair.group_key}-${pair.policy_name}" => pair
  }
  policy_arn = each.value.policy_arn
  role       = aws_iam_role.managed_node_group[each.value.group_key].name
}

# ---------------------------------------------------------------------------------------------------------------------
# OIDC Provider for IAM Roles for Service Accounts (IRSA)
# Configures an OpenID Connect (OIDC) identity provider for the EKS cluster,
# enabling Kubernetes service accounts to assume IAM roles.
# ---------------------------------------------------------------------------------------------------------------------

# Data source to retrieve the EKS cluster's OIDC issuer certificate
data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# AWS IAM OIDC provider for the EKS cluster
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  count           = var.enable_irsa ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags            = var.tags
}