# ---------------------------------------------------------------------------------------------------------------------
# EKS Cluster Security Group
# Manages the security group for the EKS control plane.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  count       = var.create_cluster_security_group ? 1 : 0
  name        = "${var.cluster_name}-cluster-sg"
  description = "Security group for the EKS control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}-cluster-sg"
    },
    var.enable_karpenter_tags ? {
      "karpenter.sh/discovery" = var.cluster_name
    } : {}
  )
}

# Allow all egress traffic from the cluster security group
resource "aws_security_group_rule" "cluster_egress_all" {
  count             = var.create_cluster_security_group ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
  security_group_id = aws_security_group.cluster[0].id
  description       = "Allow all outbound traffic from the EKS control plane"
}

# Allow inbound traffic to the public API endpoint from specified CIDR blocks
resource "aws_security_group_rule" "cluster_ingress_public_api" {
  count             = var.create_cluster_security_group && var.cluster_endpoint_public_access ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.cluster_endpoint_public_access_cidrs
  security_group_id = aws_security_group.cluster[0].id
  description       = "Allow inbound traffic to the public EKS API server endpoint"
}

# Additional custom rules for the cluster security group
resource "aws_security_group_rule" "cluster_additional_rules" {
  for_each                 = var.create_cluster_security_group ? var.cluster_security_group_additional_rules : {}
  security_group_id        = aws_security_group.cluster[0].id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  description              = each.value.description
}

# ---------------------------------------------------------------------------------------------------------------------
# EKS Node Group Security Group (Shared)
# This security group is applied to all nodes (managed and self-managed)
# to allow communication within the cluster and with the control plane.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Shared security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name"                                      = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Required for EKS cluster recognition
    },
    var.enable_karpenter_tags ? {
      "karpenter.sh/discovery" = var.cluster_name
    } : {}
  )
}

# Allow all egress traffic from worker nodes (if recommended rules are enabled)
resource "aws_security_group_rule" "node_egress_all" {
  count             = var.node_security_group_enable_recommended_rules ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
  security_group_id = aws_security_group.node.id
  description       = "Allow all outbound traffic from EKS worker nodes"
}

# Allow worker nodes to communicate with each other within the same security group
resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node.id
  description       = "Allow EKS worker nodes to communicate with each other"
}

# Allow control plane to initiate communication with worker nodes (kubelet ports)
resource "aws_security_group_rule" "node_ingress_cluster" {
  count                    = var.create_cluster_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535 # Kubelet dynamic port range
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster[0].id
  security_group_id        = aws_security_group.node.id
  description              = "Allow EKS control plane to communicate with worker nodes (kubelet)"
}

# Allow worker nodes to communicate with the EKS control plane API
resource "aws_security_group_rule" "cluster_ingress_node" {
  count                    = var.create_cluster_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster[0].id
  description              = "Allow EKS worker nodes to communicate with the EKS control plane API"
}

# Additional custom rules for the node security group
resource "aws_security_group_rule" "node_additional_rules" {
  for_each = var.node_security_group_additional_rules

  security_group_id        = aws_security_group.node.id
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = each.value.cidr_blocks
  source_security_group_id = each.value.source_security_group_id
  description              = each.value.description
}