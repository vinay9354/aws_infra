# ---------------------------------------------------------------------------------------------------------------------
# EKS Pod Identity Associations
# Manages associations between Kubernetes service accounts and IAM roles for fine-grained permissions.
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_eks_pod_identity_association" "this" {
  for_each = var.pod_identity_associations

  cluster_name    = aws_eks_cluster.this.name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = each.value.role_arn

  tags = var.tags
}