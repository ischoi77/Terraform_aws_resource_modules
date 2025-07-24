output "group_names" {
  value = [for g in aws_iam_group.this : g.name]
}
