resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

# Validation for rule combinations is handled in `variables.tf` via `validation` blocks.
# Removed the local plan-time validation here to avoid unused-declaration warnings from linters.

# Ingress rules
resource "aws_security_group_rule" "ingress" {
  for_each = {
    for idx, rule in var.ingress_rules :
    idx => rule
  }

  type              = "ingress"
  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  prefix_list_ids          = length(each.value.prefix_list_ids) > 0 ? each.value.prefix_list_ids : null
  source_security_group_id = each.value.source_security_group_id != null ? each.value.source_security_group_id : null
  self                     = each.value.self ? true : null
}

# Egress rules
resource "aws_security_group_rule" "egress" {
  for_each = {
    for idx, rule in var.egress_rules :
    idx => rule
  }

  type              = "egress"
  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  description       = each.value.description

  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks         = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
  prefix_list_ids          = length(each.value.prefix_list_ids) > 0 ? each.value.prefix_list_ids : null
  source_security_group_id = each.value.source_security_group_id != null ? each.value.source_security_group_id : null
  self                     = each.value.self ? true : null
}
