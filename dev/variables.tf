# ----------------
# Common Variables
# ----------------
variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "ap-south-1"
}
variable "allowed_account_ids" {
  description = "List of allowed AWS account IDs"
  type        = list(string)
  default     = []
}