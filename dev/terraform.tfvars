# ----------------
# Common Variables
# ----------------
aws_region          = "ap-south-1"
allowed_account_ids = [516311263797] #Dev Account ID
environment         = "vinay-infra-dev"
# -----------------------------------------------------------------------------------
# Subnets Configuration
# https://visualsubnetcalc.com/index.html?c=1N4IgbiBcIEwgNCARlEBGA7DAdDADNgXgPRoBsCIAzlKHgOa0h4AWTeAluwFbsDW7ADbsAtuwB27APZNJ0AKYBjGAFo0IAL6I0MyKDkglquBq3o5oGLv2ojKgMybE96yAN2ALJtPaxet6je2sJ6PugCoWZovJHaXLHobJGmQA
# -----------------------------------------------------------------------------------
# Public Subnets Configuration
# -----------------------------------------------------------------------------------
public_subnets = {
  ec2-1 = {
    cidr_block        = "172.20.0.0/24"
    availability_zone = "ap-south-1a"
  }
  ec2-2 = {
    cidr_block        = "172.20.1.0/24"
    availability_zone = "ap-south-1b"
  }
}
# -----------------------------------------------------------------------------------
# Priva Subnets Configuration
# -----------------------------------------------------------------------------------
private_subnets = {
  ec2-3 = {
    cidr_block        = "172.20.2.0/24"
    availability_zone = "ap-south-1a"
  }
  ec2-4 = {
    cidr_block        = "172.20.3.0/24"
    availability_zone = "ap-south-1b"
  }
}