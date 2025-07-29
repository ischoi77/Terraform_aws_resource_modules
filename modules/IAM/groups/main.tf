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

  group_policy_attachments = {
    for attachment in flatten([
      for group_key, group in local.groups : [
        for policy_name in group.policies : {
          key        = "${group_key}::${policy_name}"
          group_key  = group_key
          policy_arn = lookup(local.all_policy_arns, policy_name, null)
        }
      ]
    ]) : attachment.key => attachment
    if attachment.policy_arn != null
  }
}

resource "aws_iam_group" "this" {
  for_each = local.groups

  name = each.key
}

resource "aws_iam_group_policy_attachment" "this" {
  for_each = local.group_policy_attachments

  group      = aws_iam_group.this[each.value.group_key].name
  policy_arn = each.value.policy_arn
}