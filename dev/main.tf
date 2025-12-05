#-------------------------------------------
# VPC module
# ------------------------------------------
module "vpc" {
  source = "../modules/networking/vpc"

  name                 = "vinay-infra-vpc"
  cidr_block           = "172.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_ipv6          = false
  instance_tenancy     = "default"
  create_igw           = true

}

#---------------------------------------------------------------------------
# Public Subnets (with Internet Gateway routing)
# --------------------------------------------------------------------------
module "public_subnets" {
  source = "../modules/networking/subnets"

  for_each = var.public_subnets

  vpc_id            = module.vpc.vpc_id
  name              = "${var.environment}-${each.key}-pb-subnet-${substr(each.value.availability_zone, length(each.value.availability_zone) - 2, 2)}"
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  # Public subnet settings
  map_public_ip_on_launch = true

  # Main route: Internet Gateway for public internet access
  route_cidr_block  = "0.0.0.0/0"
  route_target_type = "igw"
  route_target_id   = module.vpc.igw_id

  # Additional routes
  extra_routes = each.value.extra_routes

  # Merge common tags, environment-specific tags, and subnet-specific tags
  tags = merge(
    {
      Environment = var.environment
      Type        = "public"
    },
    each.value.tags
  )

  # Merge default subnet tags with subnet-specific tags
  subnet_tags = merge(
    {
      SubnetType = "Public"
    },
    each.value.subnet_tags
  )
}

# #---------------------------------------------------------------
# # Private Subnets (with NAT Gateway routing)
# # --------------------------------------------------------------
module "private_subnets" {
  source = "../modules/networking/subnets"

  for_each = var.private_subnets

  vpc_id            = module.vpc.vpc_id
  name              = "${var.environment}-${each.key}-pv-subnet-${substr(each.value.availability_zone, length(each.value.availability_zone) - 2, 2)}"
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  # Private subnet settings
  map_public_ip_on_launch = false

  # Main route: NAT Gateway for outbound internet access
  # route_cidr_block  = "0.0.0.0/0"
  # route_target_type = "natgw"
  # route_target_id   = each.value.nat_gateway_id

  # Additional routes
  extra_routes = each.value.extra_routes
}

# -----------------------------
# Security Group Module
# -----------------------------
module "security_group" {
  source   = "../modules/security/security_group"
  for_each = local.security_groups

  # Use the map key as the SG name (app, db, bastion, etc.)
  name        = each.key
  description = each.value.description
  vpc_id      = module.vpc.vpc_id

  tags = lookup(each.value, "tags", {})

  ingress_rules = each.value.ingress_rules
  egress_rules  = lookup(each.value, "egress_rules", [])
}


