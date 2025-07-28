output "usernames" {
  description = "List of IAM user names created"
  value       = [for user in aws_iam_user.this : user.name]
}

output "user_arns" {
  description = "Map of IAM usernames to their ARNs"
  value = {
    for k, user in aws_iam_user.this :
    k => user.arn
  }
}

output "user_policy_attachments" {
  description = "List of IAM user + policy attachment identifiers"
  value       = keys(aws_iam_user_policy_attachment.this)
}

output "user_group_memberships" {
  description = "List of IAM users with group memberships"
  value       = keys(aws_iam_user_group_membership.this)
}

output "user_groups_map" {
  description = "Map of IAM user name to list of group names they belong to"
  value = {
    for username, membership in aws_iam_user_group_membership.this :
    username => membership.groups
  }
}

output "group_users_map" {
  description = "Map of group name to list of IAM users who belong to that group"
  value       = local.group_users_map
}