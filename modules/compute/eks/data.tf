# ---------------------------------------------------------------------------------------------------------------------
# Data Sources for EKS AMIs
# ---------------------------------------------------------------------------------------------------------------------

# Lookup EKS Optimized AMI for Amazon Linux 2 (Standard)
data "aws_ssm_parameter" "eks_optimized_ami_al2" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}



# Lookup EKS Optimized AMI for Windows 2022
data "aws_ssm_parameter" "eks_optimized_ami_windows_2022" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/windows_2022_full/recommended/image_id"
}

# Helper local to determine default AMI based on platform/type if user didn't provide one
locals {
  default_al2_ami_id     = data.aws_ssm_parameter.eks_optimized_ami_al2.value
  default_windows_ami_id = data.aws_ssm_parameter.eks_optimized_ami_windows_2022.value
}
