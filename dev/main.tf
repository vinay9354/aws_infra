#--------------
# VPC module
# -------------
module "vpc" {
  source = "../modules/networking/vpc"

  name                 = "vinay-infra-vpc"
  cidr_block           = "172.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_ipv6          = false
  instance_tenancy     = "default"
  create_igw           = true

  tags = {
    Name = "vinay-infra-vpc"
  }
}