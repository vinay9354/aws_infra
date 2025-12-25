# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for EKS Cluster Control Plane
# ---------------------------------------------------------------------------------------------------------------------

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

resource "aws_iam_role" "cluster" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# Optional: ELB permissions often needed by the control plane
resource "aws_iam_role_policy_attachment" "cluster_vpc_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Managed Node Groups (Dedicated per Group)
# ---------------------------------------------------------------------------------------------------------------------

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

resource "aws_iam_role" "managed_node_group" {
  for_each           = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  name               = "${var.cluster_name}-${each.key}-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume_role.json
  tags               = merge(var.tags, each.value.tags)
}

resource "aws_iam_role_policy_attachment" "managed_node_worker_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.managed_node_group[each.key].name
}


resource "aws_iam_role_policy_attachment" "managed_node_cni_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.managed_node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "managed_node_registry_policy" {
  for_each   = { for k, v in var.managed_node_groups : k => v if v.create_iam_role }
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.managed_node_group[each.key].name
}

resource "aws_iam_role_policy_attachment" "managed_node_additional_policies" {
  for_each = {
    for pair in flatten([
      for group_key, group_val in var.managed_node_groups : [
        for policy_name, policy_arn in group_val.iam_role_additional_policies : {
          group_key   = group_key
          policy_name = policy_name
          policy_arn  = policy_arn
        }
      ] if group_val.create_iam_role
    ]) : "${pair.group_key}-${pair.policy_name}" => pair
  }
  policy_arn = each.value.policy_arn
  role       = aws_iam_role.managed_node_group[each.value.group_key].name
}



# ---------------------------------------------------------------------------------------------------------------------
# OIDC Provider
# ---------------------------------------------------------------------------------------------------------------------

data "tls_certificate" "cluster" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  count           = var.enable_irsa ? 1 : 0
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  tags            = var.tags
}
