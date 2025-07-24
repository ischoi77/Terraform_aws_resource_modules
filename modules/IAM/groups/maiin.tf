locals {
  raw_group_data = csvdecode(file(var.group_csv_file))

  # group_name => list of policy names
  groups = {
    for g in local.raw_group_data :
    g.group_name => {
      policies = split(",", g.policies)
    }
  }

  # Flatten group-policy combinations
  group_policy_pairs = flatten([
    for group_name, group_obj in local.groups : [
      for policy_name in group_obj.policies : {
        key        = "${group_name}-${trimspace(policy_name)}"
        group_name = group_name
        policy_arn = var.policy_arns[trimspace(policy_name)]
      }
    ]
  ])

  group_policy_map = {
    for item in local.group_policy_pairs :
    item.key => {
      group_name = item.group_name
      policy_arn = item.policy_arn
    }
  }
}

resource "aws_iam_group" "this" {
  for_each = local.groups

  name = each.key
}

resource "aws_iam_group_policy_attachment" "this" {
  for_each = local.group_policy_map

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}
