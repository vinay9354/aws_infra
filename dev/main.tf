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

  # Main route: NAT instance for outbound internet access
  route_cidr_block  = "0.0.0.0/0"
  route_target_type = "eni"
  route_target_id   = module.ec2_instances["vinay-dev-infra-nat-instance"].primary_network_interface_id

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

  ingress_rules = lookup(each.value, "ingress_rules", [])
  egress_rules  = lookup(each.value, "egress_rules", [])
}

# --------------------------------
# Create EC2 instances using module
# --------------------------------
# This module block will create one module instance per key in local.ec2_instances.
# It maps the fields from each.value into the module input variables expected by the EC2 module.
module "ec2_instances" {
  source   = "../modules/compute/ec2"
  for_each = local.ec2_instances

  # Core settings
  create_instance                      = lookup(each.value, "create_instance", true)
  name                                 = lookup(each.value, "name", each.key)
  ami_id                               = lookup(each.value, "ami_id", null)
  instance_type                        = lookup(each.value, "instance_type", "t3.micro")
  key_name                             = lookup(each.value, "key_name", null)
  subnet_id                            = lookup(each.value, "subnet_id", null)
  security_group_ids                   = lookup(each.value, "security_group_ids", [])
  iam_instance_profile                 = lookup(each.value, "iam_instance_profile", null)
  associate_public_ip_address          = lookup(each.value, "associate_public_ip_address", false)
  user_data                            = lookup(each.value, "user_data", null)
  user_data_base64                     = lookup(each.value, "user_data_base64", null)
  enable_monitoring                    = lookup(each.value, "enable_monitoring", false)
  ebs_optimized                        = lookup(each.value, "ebs_optimized", false)
  source_dest_check                    = lookup(each.value, "source_dest_check", true)
  disable_api_termination              = lookup(each.value, "disable_api_termination", false)
  instance_initiated_shutdown_behavior = lookup(each.value, "instance_initiated_shutdown_behavior", "stop")
  placement_group                      = lookup(each.value, "placement_group", null)
  tenancy                              = lookup(each.value, "tenancy", "default")
  host_id                              = lookup(each.value, "host_id", null)

  # CPU options
  cpu_core_count       = lookup(each.value, "cpu_core_count", null)
  cpu_threads_per_core = lookup(each.value, "cpu_threads_per_core", null)
  availability_zone    = lookup(each.value, "availability_zone", null)

  # Block device and EBS settings
  root_block_device       = lookup(each.value, "root_block_device", null)
  ebs_block_devices       = lookup(each.value, "ebs_block_devices", [])
  ephemeral_block_devices = lookup(each.value, "ephemeral_block_devices", [])
  additional_ebs_volumes  = lookup(each.value, "additional_ebs_volumes", {})

  # Network interfaces
  network_interfaces            = lookup(each.value, "network_interfaces", [])
  create_network_interfaces     = lookup(each.value, "create_network_interfaces", false)
  network_interface_configs     = lookup(each.value, "network_interface_configs", {})
  additional_network_interfaces = lookup(each.value, "additional_network_interfaces", {})

  # Metadata / IMDS
  metadata_options = lookup(each.value, "metadata_options", {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  })

  # CPU credits / misc
  cpu_credits = lookup(each.value, "cpu_credits", null)

  # Tagging
  tags        = lookup(each.value, "tags", {})
  volume_tags = lookup(each.value, "volume_tags", {})

  # Elastic IP
  create_eip = lookup(each.value, "create_eip", false)

  # IAM role options
  create_iam_role                = lookup(each.value, "create_iam_role", false)
  existing_iam_role_name         = lookup(each.value, "existing_iam_role_name", null)
  attach_ssm_policy              = lookup(each.value, "attach_ssm_policy", true)
  attach_cloudwatch_agent_policy = lookup(each.value, "attach_cloudwatch_agent_policy", true)
  additional_iam_policy_arns     = lookup(each.value, "additional_iam_policy_arns", [])

  # Key pair options
  create_key_pair                = lookup(each.value, "create_key_pair", false)
  key_pair_name                  = lookup(each.value, "key_pair_name", null)
  key_pair_algorithm             = lookup(each.value, "key_pair_algorithm", "RSA")
  key_pair_rsa_bits              = lookup(each.value, "key_pair_rsa_bits", 4096)
  store_key_pair_in_ssm          = lookup(each.value, "store_key_pair_in_ssm", true)
  private_key_ssm_parameter_name = lookup(each.value, "private_key_ssm_parameter_name", null)
  public_key_ssm_parameter_name  = lookup(each.value, "public_key_ssm_parameter_name", null)

  # Spot instance options
  use_spot_instance                   = lookup(each.value, "use_spot_instance", false)
  spot_price                          = lookup(each.value, "spot_price", null)
  spot_wait_for_fulfillment           = lookup(each.value, "spot_wait_for_fulfillment", true)
  spot_type                           = lookup(each.value, "spot_type", "persistent")
  spot_instance_interruption_behavior = lookup(each.value, "spot_instance_interruption_behavior", "stop")
  spot_valid_until                    = lookup(each.value, "spot_valid_until", null)

  # Instance state management
  manage_instance_state       = lookup(each.value, "manage_instance_state", false)
  instance_state              = lookup(each.value, "instance_state", "running")
  force_instance_state_change = lookup(each.value, "force_instance_state_change", false)

  # Safety / defaults - if you need to forward additional module vars later,
  # add them both to the locals map and forward them here using lookup(each.value, "<key>", <default>).
}

# -----------------------------
# IAM Policy Module
# -----------------------------
module "iam_policies" {
  source   = "../modules/security/iam_policy"
  for_each = local.iam_policies

  name        = each.key
  description = lookup(each.value, "description", null)
  path        = lookup(each.value, "path", "/")
  policy      = each.value.policy
  tags        = lookup(each.value, "tags", {})
}

# -----------------------------
# IAM Role Module
# -----------------------------
module "iam_roles" {
  source   = "../modules/security/iam_role"
  for_each = local.iam_roles

  name                    = each.key
  description             = lookup(each.value, "description", "Managed by Terraform")
  assume_role_policy      = each.value.assume_role_policy
  policy_arns             = lookup(each.value, "policy_arns", [])
  create_instance_profile = lookup(each.value, "create_instance_profile", false)
  path                    = lookup(each.value, "path", "/")
  max_session_duration    = lookup(each.value, "max_session_duration", 3600)
  tags                    = lookup(each.value, "tags", {})
}

# --------------------------------
# EKS Cluster Module
# --------------------------------
module "dev_eks" {
  source = "../modules/compute/eks"

  # Basic cluster configuration
  cluster_name    = local.eks_cluster_config.cluster_name
  cluster_version = local.eks_cluster_config.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = local.eks_cluster_config.subnet_ids

  # Endpoint access
  cluster_endpoint_private_access      = local.eks_cluster_config.cluster_endpoint_private_access
  cluster_endpoint_public_access       = local.eks_cluster_config.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = local.eks_cluster_config.cluster_endpoint_public_access_cidrs

  # Cluster logging
  cluster_enabled_log_types = local.eks_cluster_config.enable_cluster_logging ? [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ] : []

  # IRSA and KMS
  enable_irsa    = local.eks_cluster_config.enable_irsa
  create_kms_key = local.eks_cluster_config.create_kms_key

  # Enable cluster creator as admin
  enable_cluster_creator_admin_permissions = true

  # Managed Node Groups with Spot Instances
  managed_node_groups = local.eks_cluster_config.managed_node_groups

  # Cluster Add-ons
  cluster_addons = local.eks_cluster_config.cluster_addons

  # Tags
  tags = local.eks_cluster_config.tags
}
