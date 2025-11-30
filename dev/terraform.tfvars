# ----------------
# Common Variables
# ----------------
aws_region          = "ap-south-1"
allowed_account_ids = [516311263797] #Dev Account ID
environment         = "vinay-inra-dev"
# -----------------------------------------------------------------------------------
# Subnets Configuration
# https://visualsubnetcalc.com/index.html?c=1N4IgbiBcIEwgNCARlEBGA7DAdDADNgXgPRoBsCIAzlKHgOa0h4AWTeAluwFbsDW7ADbsAtuwB27APZNJ0AKYBjGAFo0IAL6I0MyKDkglquBq3o5wU9rF6r6YbbNoBj7b1fouHtG0emgA
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
