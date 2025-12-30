# ---------------------------------------------------------------------------------------------------------------------
# IAM Role for Fargate
# Defines the IAM role that EKS Fargate pods will assume for execution.
# ---------------------------------------------------------------------------------------------------------------------

# Policy document for the Fargate pod execution role to assume
data "aws_iam_policy_document" "fargate_assume_role" {
  count = length(var.fargate_profiles) > 0 ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

# IAM Role for Fargate profiles
resource "aws_iam_role" "fargate" {
  count              = length(var.fargate_profiles) > 0 ? 1 : 0
  name               = "${var.cluster_name}-fargate-role"
  assume_role_policy = data.aws_iam_policy_document.fargate_assume_role[0].json
  tags               = var.tags
}

# Attach the AmazonEKSFargatePodExecutionRolePolicy to the Fargate IAM role
resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role_policy" {
  count      = length(var.fargate_profiles) > 0 ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate[0].name
}

# Attach additional IAM policies specified in Fargate profile configuration
resource "aws_iam_role_policy_attachment" "fargate_additional" {
  for_each = {
    for pair in flatten([
      for profile_key, profile_val in var.fargate_profiles : [
        for policy_name, policy_arn in profile_val.iam_role_additional_policies : {
          profile_key = profile_key
          policy_name = policy_name
          policy_arn  = policy_arn
        }
      ] if profile_val.create_iam_role # Only attach if a role is being created by the module
    ]) : "${pair.profile_key}-${pair.policy_name}" => pair
  }

  policy_arn = each.value.policy_arn
  role       = aws_iam_role.fargate[0].name
}

# ---------------------------------------------------------------------------------------------------------------------
# Fargate Profiles
# Provisions EKS Fargate profiles for running pods on serverless compute.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eks_fargate_profile" "this" {
  for_each = var.fargate_profiles

  cluster_name         = aws_eks_cluster.this.name
  fargate_profile_name = each.value.name
  # Use the created IAM role or a pre-existing one
  pod_execution_role_arn = each.value.create_iam_role ? aws_iam_role.fargate[0].arn : each.value.iam_role_arn

  # Subnet selection logic: use profile-specific subnets if provided,
  # otherwise fall back to node_group_subnet_ids, then general subnet_ids.
  subnet_ids = length(each.value.subnet_ids != null ? each.value.subnet_ids : []) > 0 ? each.value.subnet_ids : (length(var.node_group_subnet_ids) > 0 ? var.node_group_subnet_ids : var.subnet_ids)

  # Define selectors to match pods to this Fargate profile
  dynamic "selector" {
    for_each = each.value.selectors
    content {
      namespace = selector.value.namespace
      labels    = selector.value.labels
    }
  }

  tags = merge(
    var.tags,
    each.value.tags
  )
}