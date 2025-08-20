locals {
  groups_raw = csvdecode(file(var.group_csv_file))

  # group_name => list of policy names
  groups = {
    for g in local.groups_raw : g.group_name => {
      name     = g.group_name
      policies = g.policies == "" ? [] : split(",", g.policies)
    }
  }
  
  all_policy_arns = merge(
    var.managed_policy_arns,
    var.custom_policy_arns
  )

  group_policy_attachments_flat = flatten([
    for group_name, group in local.groups : [
      for policy_name in group.policies : {
        key        = "${group_name}::${policy_name}"
        group_name = group_name
        policy_arn = lookup(local.all_policy_arns, trimspace(policy_name), null)
      }
    ]
  ])

  group_policy_attachments = {
    for a in local.group_policy_attachments_flat : a.key => a
  }
}

resource "aws_iam_group" "this" {
  for_each = local.groups

  name = each.key
}

# 그룹 이름 기반 데이터 소스
# data "aws_iam_group" "this" {
#   for_each = local.groups

#   group_name = each.key
# }

# 그룹 정책 연결 (data source 기반)
resource "aws_iam_group_policy_attachment" "this" {
  for_each = local.group_policy_attachments

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}