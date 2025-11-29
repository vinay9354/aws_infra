terraform {
  required_version = "~> 1.12.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22.1"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = var.allowed_account_ids
  default_tags {
    tags = {
      Owner       = "vinay"
      Managed_by  = "terraform"
      Environment = "dev"
    }
  }
}
