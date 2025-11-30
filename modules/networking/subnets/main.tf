resource "aws_subnet" "this" {
  vpc_id                          = var.vpc_id
  cidr_block                      = var.cidr_block
  ipv6_cidr_block                 = var.ipv6_cidr_block
  availability_zone               = var.availability_zone
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.assign_ipv6_address_on_creation

  tags = merge(
    {
      Name = var.name
    },
    var.tags,
    var.subnet_tags
  )

  lifecycle {
    # Prevent accidental deletion of subnets with running resources
    # Set to true in production environments if needed
    prevent_destroy = false

    # Uncomment to ignore external tag changes
    # ignore_changes = [tags]
  }
}

resource "aws_route_table" "this" {
  count = var.create_route_table ? 1 : 0

  vpc_id = var.vpc_id

  tags = merge(
    {
      Name = "${var.name}-rt"
    },
    var.tags,
    var.route_table_tags
  )
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = var.create_route_table ? aws_route_table.this[0].id : var.existing_route_table_id
}

# Main/default route (optional - only created if route_target_id is provided)
resource "aws_route" "main_ipv4" {
  count = var.create_route_table && var.route_target_id != null && var.route_target_id != "" && var.route_cidr_block != null ? 1 : 0

  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = var.route_cidr_block

  gateway_id                = var.route_target_type == "igw" ? var.route_target_id : null
  nat_gateway_id            = var.route_target_type == "natgw" ? var.route_target_id : null
  transit_gateway_id        = var.route_target_type == "tgw" ? var.route_target_id : null
  vpc_endpoint_id           = var.route_target_type == "vpce" ? var.route_target_id : null
  network_interface_id      = var.route_target_type == "eni" ? var.route_target_id : null
  vpc_peering_connection_id = var.route_target_type == "pcx" ? var.route_target_id : null
}

# Main IPv6 route (optional)
resource "aws_route" "main_ipv6" {
  count = var.create_route_table && var.route_target_id != null && var.route_target_id != "" && var.route_ipv6_cidr_block != null ? 1 : 0

  route_table_id              = aws_route_table.this[0].id
  destination_ipv6_cidr_block = var.route_ipv6_cidr_block

  gateway_id                = var.route_target_type == "igw" ? var.route_target_id : null
  nat_gateway_id            = var.route_target_type == "natgw" ? var.route_target_id : null
  transit_gateway_id        = var.route_target_type == "tgw" ? var.route_target_id : null
  vpc_endpoint_id           = var.route_target_type == "vpce" ? var.route_target_id : null
  network_interface_id      = var.route_target_type == "eni" ? var.route_target_id : null
  vpc_peering_connection_id = var.route_target_type == "pcx" ? var.route_target_id : null
}

# Extra routes (0..N), created in a loop
locals {
  extra_routes_map = {
    for idx, r in var.extra_routes :
    idx => r
  }
}

# Extra IPv4 routes
resource "aws_route" "extra_ipv4" {
  for_each = var.create_route_table ? {
    for k, v in local.extra_routes_map :
    k => v if v.destination_cidr_block != null && v.destination_cidr_block != ""
  } : {}

  route_table_id         = aws_route_table.this[0].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id                = each.value.target_type == "igw" ? each.value.target_id : null
  nat_gateway_id            = each.value.target_type == "natgw" ? each.value.target_id : null
  transit_gateway_id        = each.value.target_type == "tgw" ? each.value.target_id : null
  vpc_endpoint_id           = each.value.target_type == "vpce" ? each.value.target_id : null
  network_interface_id      = each.value.target_type == "eni" ? each.value.target_id : null
  vpc_peering_connection_id = each.value.target_type == "pcx" ? each.value.target_id : null
}

# Extra IPv6 routes
resource "aws_route" "extra_ipv6" {
  for_each = var.create_route_table ? {
    for k, v in local.extra_routes_map :
    k => v if v.destination_ipv6_cidr_block != null && v.destination_ipv6_cidr_block != ""
  } : {}

  route_table_id              = aws_route_table.this[0].id
  destination_ipv6_cidr_block = each.value.destination_ipv6_cidr_block

  gateway_id                = each.value.target_type == "igw" ? each.value.target_id : null
  nat_gateway_id            = each.value.target_type == "natgw" ? each.value.target_id : null
  transit_gateway_id        = each.value.target_type == "tgw" ? each.value.target_id : null
  vpc_endpoint_id           = each.value.target_type == "vpce" ? each.value.target_id : null
  network_interface_id      = each.value.target_type == "eni" ? each.value.target_id : null
  vpc_peering_connection_id = each.value.target_type == "pcx" ? each.value.target_id : null
}

# Extra prefix list routes
resource "aws_route" "extra_prefix_list" {
  for_each = var.create_route_table ? {
    for k, v in local.extra_routes_map :
    k => v if v.destination_prefix_list_id != null && v.destination_prefix_list_id != ""
  } : {}

  route_table_id             = aws_route_table.this[0].id
  destination_prefix_list_id = each.value.destination_prefix_list_id

  gateway_id                = each.value.target_type == "igw" ? each.value.target_id : null
  nat_gateway_id            = each.value.target_type == "natgw" ? each.value.target_id : null
  transit_gateway_id        = each.value.target_type == "tgw" ? each.value.target_id : null
  vpc_endpoint_id           = each.value.target_type == "vpce" ? each.value.target_id : null
  network_interface_id      = each.value.target_type == "eni" ? each.value.target_id : null
  vpc_peering_connection_id = each.value.target_type == "pcx" ? each.value.target_id : null
}
