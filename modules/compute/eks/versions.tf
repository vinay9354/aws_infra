# ---------------------------------------------------------------------------------------------------------------------
# Terraform and Provider Versions
# Defines the required Terraform version and provider versions for this EKS module.
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = "~> 1.14.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1.0"
    }
  }
}