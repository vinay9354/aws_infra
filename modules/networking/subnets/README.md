# AWS Subnet Module

## Overview

This Terraform module provides a flexible and comprehensive solution for deploying AWS subnets. It supports both IPv4 and IPv6, allowing you to create dual-stack subnets. The module automatically provisions an associated route table and enables highly configurable routing options, including support for various target types like Internet Gateways, NAT Gateways, Transit Gateways, and VPC Endpoints. You can choose to create a new route table or integrate with an existing one. Designed for resilience, it includes lifecycle protection and detailed tagging capabilities for easy management and identification of resources.

## Features

- ✅ **IPv4 and IPv6 Support**: Supports both IPv4 and IPv6, enabling the creation of single-stack or dual-stack subnets to accommodate diverse network requirements.
- ✅ **Flexible Routing Options**: Configurable main route and support for multiple target types (Internet Gateway, NAT Gateway, Transit Gateway, VPC Endpoint, ENI, VPC Peering) to direct traffic efficiently.
- ✅ **Optional Main Route**: Allows you to skip the creation of a main route, ideal for isolated or private subnets that do not require external connectivity.
- ✅ **Multiple Custom Routes**: Easily add any number of additional, custom routes to the subnet's route table for granular traffic control.
- ✅ **AWS Prefix List Integration**: Supports routing traffic to AWS-managed or custom prefix lists, simplifying access to various AWS services or other networks.
- ✅ **Existing Route Table Integration**: Provides the option to associate the subnet with an existing route table, allowing for shared routing configurations and resource optimization.
- ✅ **Comprehensive Tagging**: Granular control over tags for subnets and route tables, facilitating resource organization, cost allocation, and operational management.
- ✅ **Lifecycle Management**: Includes lifecycle rules to prevent accidental destruction of critical subnets and their associated route tables.

## Usage

This section demonstrates various configurations for deploying subnets using this module.

### Basic Public Subnet with Internet Gateway

```hcl
module "public_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "public-subnet-1a"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  
  map_public_ip_on_launch = true
  
  route_cidr_block   = "0.0.0.0/0"
  route_target_type  = "igw"
  route_target_id    = module.internet_gateway.igw_id

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### Private Subnet with NAT Gateway

```hcl
module "private_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "private-subnet-1a"
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  
  map_public_ip_on_launch = false
  
  route_cidr_block   = "0.0.0.0/0"
  route_target_type  = "natgw"
  route_target_id    = module.nat_gateway.nat_gateway_id

  tags = {
    Environment = "production"
    Type        = "private"
  }
}
```

### Dual-Stack Subnet (IPv4 + IPv6)

```hcl
module "dual_stack_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "dual-stack-subnet-1a"
  cidr_block        = "10.0.20.0/24"
  ipv6_cidr_block   = "2001:db8::/64"
  availability_zone = "us-east-1a"
  
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  
  # IPv4 route
  route_cidr_block      = "0.0.0.0/0"
  # IPv6 route
  route_ipv6_cidr_block = "::/0"
  route_target_type     = "igw"
  route_target_id       = module.internet_gateway.igw_id

  tags = {
    Environment = "production"
    Stack       = "dual"
  }
}
```

### Isolated Subnet (No Routes)

```hcl
module "isolated_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "isolated-subnet-1a"
  cidr_block        = "10.0.30.0/24"
  availability_zone = "us-east-1a"
  
  # No route_target_id means no main route is created
  route_target_id = null

  tags = {
    Environment = "production"
    Type        = "isolated"
  }
}
```

### Subnet with Multiple Routes

```hcl
module "multi_route_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "multi-route-subnet-1a"
  cidr_block        = "10.0.40.0/24"
  availability_zone = "us-east-1a"
  
  # Main route to Internet Gateway
  route_cidr_block   = "0.0.0.0/0"
  route_target_type  = "igw"
  route_target_id    = module.internet_gateway.igw_id

  # Additional routes
  extra_routes = [
    {
      destination_cidr_block      = "10.1.0.0/16"
      destination_ipv6_cidr_block = null
      destination_prefix_list_id  = null
      target_type                 = "tgw"
      target_id                   = "tgw-1234567890abcdef"
    },
    {
      destination_cidr_block      = "10.2.0.0/16"
      destination_ipv6_cidr_block = null
      destination_prefix_list_id  = null
      target_type                 = "pcx"
      target_id                   = "pcx-1234567890abcdef"
    },
    {
      destination_cidr_block      = null
      destination_ipv6_cidr_block = null
      destination_prefix_list_id  = "pl-1234567890abcdef"
      target_type                 = "igw"
      target_id                   = module.internet_gateway.igw_id
    }
  ]

  tags = {
    Environment = "production"
    Type        = "multi-route"
  }
}
```

### Using an Existing Route Table

```hcl
module "subnet_with_existing_rt" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "subnet-shared-rt"
  cidr_block        = "10.0.50.0/24"
  availability_zone = "us-east-1a"
  
  # Use existing route table instead of creating a new one
  create_route_table       = false
  existing_route_table_id  = "rtb-1234567890abcdef"

  tags = {
    Environment = "production"
  }
}
```

### Subnet with Transit Gateway Route

```hcl
module "tgw_subnet" {
  source = "./modules/networking/subnets"

  vpc_id            = module.vpc.vpc_id
  name              = "tgw-subnet-1a"
  cidr_block        = "10.0.60.0/24"
  availability_zone = "us-east-1a"
  
  route_cidr_block   = "0.0.0.0/0"
  route_target_type  = "tgw"
  route_target_id    = "tgw-1234567890abcdef"

  tags = {
    Environment = "production"
    Type        = "transit"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.14.1 |
| aws | ~> 6.27.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | The ID of the VPC where the subnet will be provisioned. | `string` | n/a | yes |
| name | A unique name for the subnet, which will also be used for the `Name` tag. | `string` | n/a | yes |
| cidr_block | The IPv4 CIDR block for the subnet (e.g., `10.0.1.0/24`). | `string` | n/a | yes |
| availability_zone | The AWS Availability Zone in which to create the subnet (e.g., `us-east-1a`). | `string` | n/a | yes |
| ipv6_cidr_block | The IPv6 CIDR block for the subnet (e.g., `2001:db8::/64`). Required for IPv6-only or dual-stack subnets. | `string` | `null` | no |
| map_public_ip_on_launch | Controls whether instances launched in this subnet are assigned a public IPv4 address by default. | `bool` | `false` | no |
| assign_ipv6_address_on_creation | Controls whether instances launched in this subnet are assigned an IPv6 address by default. Only applicable if `ipv6_cidr_block` is set. | `bool` | `false` | no |
| create_route_table | If `true`, a new route table will be created and associated with the subnet. If `false`, `existing_route_table_id` must be provided. | `bool` | `true` | no |
| existing_route_table_id | The ID of an existing route table to associate with the subnet. Required if `create_route_table` is `false`. | `string` | `null` | no |
| route_cidr_block | The IPv4 CIDR block for the main route (e.g., `0.0.0.0/0` for an Internet route). | `string` | `"0.0.0.0/0"` | no |
| route_ipv6_cidr_block | The IPv6 CIDR block for the main route (e.g., `::/0` for an IPv6 Internet route). | `string` | `null` | no |
| route_target_type | The type of target for the main route. Accepted values: `igw`, `natgw`, `tgw`, `vpce`, `eni`, `pcx`. | `string` | `"igw"` | no |
| route_target_id | The ID of the route target (e.g., Internet Gateway ID, NAT Gateway ID). Set to `null` or an empty string to skip creating the main route. | `string` | `null` | no |
| extra_routes | A list of additional route objects to be added to the associated route table. See `extra_routes Object Structure` for details. | `list(object)` | `[]` | no |
| tags | A map of key-value pairs to apply as default tags to all resources created by this module (subnet and route table). | `map(string)` | `{}` | no |
| subnet_tags | A map of key-value pairs for additional tags specifically for the AWS Subnet resource. These will merge with `tags`. | `map(string)` | `{}` | no |
| route_table_tags | A map of key-value pairs for additional tags specifically for the AWS Route Table resource. These will merge with `tags` and only apply if `create_route_table` is `true`. | `map(string)` | `{}` | no |

### extra_routes Object Structure

```hcl
{
  destination_cidr_block      = string (optional)
  destination_ipv6_cidr_block = string (optional)
  destination_prefix_list_id  = string (optional)
  target_type                 = string (required: "igw"|"natgw"|"tgw"|"vpce"|"eni"|"pcx")
  target_id                   = string (required)
}
```

**Note**: Each route must have at least one destination type specified (CIDR, IPv6 CIDR, or prefix list).

## Outputs

| Name | Description |
|------|-------------|\
| subnet_id | The unique identifier of the created subnet. |\
| subnet_arn | The Amazon Resource Name (ARN) of the created subnet. |\
| subnet_cidr_block | The IPv4 CIDR block assigned to the subnet. |\
| subnet_ipv6_cidr_block | The IPv6 CIDR block assigned to the subnet (will be `null` if not configured). |\
| availability_zone | The AWS Availability Zone in which the subnet resides. |\
| availability_zone_id | The ID of the Availability Zone (e.g., `use1-az1`). |\
| route_table_id | The unique identifier of the route table associated with this subnet. This will be the newly created route table ID or the `existing_route_table_id`. |\
| route_table_arn | The Amazon Resource Name (ARN) of the route table. This will be `null` if an `existing_route_table_id` was used. |\
| route_table_association_id | The ID of the association between the subnet and its route table. |\

## Route Target Types

| Type | Description | Example Resource |
|------|-------------|------------------|
| `igw` | Internet Gateway | `aws_internet_gateway` |
| `natgw` | NAT Gateway | `aws_nat_gateway` |
| `tgw` | Transit Gateway | `aws_ec2_transit_gateway` |
| `vpce` | VPC Endpoint | `aws_vpc_endpoint` |
| `eni` | Elastic Network Interface | `aws_network_interface` |
| `pcx` | VPC Peering Connection | `aws_vpc_peering_connection` |

## Notes

- **Isolated Subnets**: To create a subnet that is truly isolated and has no default or main route, ensure `route_target_id` is set to `null`.
- **IPv6**: For successful IPv6 subnet creation and routing, verify that your VPC has an IPv6 CIDR block assigned to it.
- **Lifecycle Protection**: By default, `prevent_destroy` is set to `false` for the created subnet and route table. It is highly recommended to enable this for production environments to prevent accidental deletion.
- **External Route Tables**: If you utilize an `existing_route_table_id`, this module will only associate the subnet with it and will not create or manage any route table resources (including routes).
- **Prefix Lists**: These are valuable for consolidating routing to specific AWS services (e.g., S3, DynamoDB) or other networks through Gateway VPC Endpoints or other specified targets.

## License

This module is maintained as part of your AWS infrastructure project and is subject to the terms defined within your project's overall licensing.