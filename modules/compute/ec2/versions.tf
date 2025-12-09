terraform {
  required_version = "~> 1.14.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.22.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}