output "group_names" {
  value = [for g in aws_iam_group.this : g.name]
}

# output "group_policy_attachments" {
#   value = {
#     for k, v in aws_iam_group_policy_attachment.this :
#     k => {
#       group      = v.group
#       policy_arn = v.policy_arn
#     }
#   }
#   description = "Map of IAM group to attached policy ARNs"
# }