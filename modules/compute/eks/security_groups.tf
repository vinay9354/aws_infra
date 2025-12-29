# ---------------------------------------------------------------------------------------------------------------------
# Cluster Security Group
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "cluster" {
  count       = var.create_cluster_security_group ? 1 : 0
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
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

# Allow control plane to communicate with worker nodes

resource "aws_security_group_rule" "cluster_egress_all" {

  count = var.create_cluster_security_group ? 1 : 0

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]

  ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null

  security_group_id = aws_security_group.cluster[0].id

  description = "Allow all egress traffic"

}



# Allow inbound traffic from the internet to the API server (controlled by variable)

resource "aws_security_group_rule" "cluster_ingress_public_api" {

  count = var.create_cluster_security_group && var.cluster_endpoint_public_access ? 1 : 0

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = var.cluster_endpoint_public_access_cidrs

  security_group_id = aws_security_group.cluster[0].id

  description = "Allow inbound traffic from the internet to the API server"

}



# Additional Rules for Cluster Security Group

resource "aws_security_group_rule" "cluster_additional_rules" {

  for_each = var.create_cluster_security_group ? var.cluster_security_group_additional_rules : {}



  security_group_id = aws_security_group.cluster[0].id

  type = each.value.type

  from_port = each.value.from_port

  to_port = each.value.to_port

  protocol = each.value.protocol

  cidr_blocks = each.value.cidr_blocks

  source_security_group_id = each.value.source_security_group_id

  description = each.value.description

}



# ---------------------------------------------------------------------------------------------------------------------

# Node Group Security Group (Shared)

# ---------------------------------------------------------------------------------------------------------------------

# This SG is applied to all nodes to allow them to talk to each other and the control plane.



resource "aws_security_group" "node" {

  name = "${var.cluster_name}-node-sg"

  description = "EKS node shared security group"

  vpc_id = var.vpc_id



  tags = merge(

    var.tags,

    {

      "Name"                                      = "${var.cluster_name}-node-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    var.enable_karpenter_tags ? {
      "karpenter.sh/discovery" = var.cluster_name

    } : {}

  )

}



resource "aws_security_group_rule" "node_egress_all" {

  count = var.node_security_group_enable_recommended_rules ? 1 : 0

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]

  ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null

  security_group_id = aws_security_group.node.id

  description = "Allow all egress traffic"

}

resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.node.id
  description       = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "node_ingress_cluster" {
  count                    = var.create_cluster_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster[0].id
  security_group_id        = aws_security_group.node.id
  description              = "Allow control plane to receive API requests from nodes"
}

resource "aws_security_group_rule" "cluster_ingress_node" {
  count                    = var.create_cluster_security_group ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.cluster[0].id
  description              = "Allow nodes to communicate with the control plane API"
}

# Additional Rules for Node Security Group
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
