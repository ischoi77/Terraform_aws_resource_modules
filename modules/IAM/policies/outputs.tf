output "user_policy_arns" {
  value = merge(
    { for k, v in aws_iam_policy.user : k => v.arn },
    { for k, v in data.aws_iam_policy.aws_managed_user : k => v.arn }
  )
}

output "group_policy_arns" {
  value = merge(
    { for k, v in aws_iam_policy.group : k => v.arn },
    { for k, v in data.aws_iam_policy.aws_managed_group : k => v.arn }
  )
}

output "role_inline_policies" {
  value = local.role_policy_map
}

output "aws_managed_role_policy_arns" {
  value = {
    for k, v in data.aws_iam_policy.aws_managed_role : k => v.arn
  }
}
