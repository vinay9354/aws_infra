resource "aws_iam_policy" "this" {
  name        = var.name
  path        = var.path
  description = var.description
  policy      = var.policy

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}
