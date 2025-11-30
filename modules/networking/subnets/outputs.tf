output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.this.id
}

output "subnet_arn" {
  description = "ARN of the subnet"
  value       = aws_subnet.this.arn
}

output "subnet_cidr_block" {
  description = "IPv4 CIDR block of the subnet"
  value       = aws_subnet.this.cidr_block
}

output "subnet_ipv6_cidr_block" {
  description = "IPv6 CIDR block of the subnet"
  value       = aws_subnet.this.ipv6_cidr_block
}

output "availability_zone" {
  description = "Availability zone of the subnet"
  value       = aws_subnet.this.availability_zone
}

output "availability_zone_id" {
  description = "Availability zone ID of the subnet"
  value       = aws_subnet.this.availability_zone_id
}

output "route_table_id" {
  description = "ID of the route table associated with this subnet"
  value       = var.create_route_table ? aws_route_table.this[0].id : var.existing_route_table_id
}

output "route_table_arn" {
  description = "ARN of the route table associated with this subnet (null if using existing route table)"
  value       = var.create_route_table ? aws_route_table.this[0].arn : null
}

output "route_table_association_id" {
  description = "ID of the route table association"
  value       = aws_route_table_association.this.id
}
