# Terraform Backend Configuration for Dev Environment
terraform {
  backend "s3" {
    bucket       = "vinay-terraform-state-dev"
    key          = "aws_infra/dev/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}


# ----------------------------------
# Backend Bucket for Terraform State
# ----------------------------------

module "backen-bucket" {
  source            = "../modules/data/s3"
  bucket_name       = "vinay-terraform-state-dev"
  force_destroy     = false
  enable_versioning = true

  # Public access settings (defaults shown for clarity)
  acl                     = "private"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_ownership        = "BucketOwnerPreferred"

}