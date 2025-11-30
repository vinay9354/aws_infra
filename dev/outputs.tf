#--------------
# Outputs
# -------------
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "igw_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs"
  value = {
    for k, v in module.public_subnets : k => v.subnet_id
  }
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs"
  value = {
    for k, v in module.private_subnets : k => v.subnet_id
  }
}

output "public_route_table_ids" {
  description = "Map of public subnet route table IDs"
  value = {
    for k, v in module.public_subnets : k => v.route_table_id
  }
}

output "private_route_table_ids" {
  description = "Map of private subnet route table IDs"
  value = {
    for k, v in module.private_subnets : k => v.route_table_id
  }
}
