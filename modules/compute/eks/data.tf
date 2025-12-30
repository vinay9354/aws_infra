# ---------------------------------------------------------------------------------------------------------------------
# Data Sources for EKS AMIs
# ---------------------------------------------------------------------------------------------------------------------

# Lookup EKS Optimized AMI for Amazon Linux 2023 (Standard)
data "aws_ssm_parameter" "eks_optimized_ami_al2023" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# Lookup EKS Optimized AMI for Windows 2022
data "aws_ssm_parameter" "eks_optimized_ami_windows_2022" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-EKS_Optimized-${var.cluster_version}/image_id"

}

# Helper local to determine default AMI based on platform/type if user didn't provide one
locals {
  default_linux_ami_id   = data.aws_ssm_parameter.eks_optimized_ami_al2023.value
  default_windows_ami_id = data.aws_ssm_parameter.eks_optimized_ami_windows_2022.value
}
