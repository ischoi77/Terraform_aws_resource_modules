# output "policy_arns" {
#   value = { for k, v in aws_iam_policy.this : k => v.arn }
# }


output "user_policy_arns" {
  description = "Map of user policy name to ARN"
  value = {
    for k, v in aws_iam_policy.user : k => v.arn
  }
}

output "group_policy_arns" {
  description = "Map of group policy name to ARN"
  value = {
    for k, v in aws_iam_policy.group : k => v.arn
  }
}
