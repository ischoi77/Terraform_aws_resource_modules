output "role_names" {
  value = [for r in aws_iam_role.this : r.name]
}

output "role_arns" {
  value = { for k, r in aws_iam_role.this : k => r.arn }
}


output "skipped_roles_missing_assume_policy_file" {
  value = [
    for role_name in keys(local.roles) :
    role_name
    if !fileexists("${path.root}/assume_role_policy_files/${role_name}.json")
  ]
}