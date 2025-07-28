# locals {
#   users_raw = csvdecode(file(var.user_csv_file))

#   users = {
#     for u in local.users_raw : u.username => {
#       username = u.username
#       policies = u.policies == "" ? [] : split(",", u.policies)
#       groups   = u.groups == "" ? [] : split(",", u.groups)
#     }
#   }

#   user_policy_pairs = flatten([
#     for user_key, user in local.users : [
#       for policy in user.policies : {
#         user_key   = user_key
#         policy_key = trimspace(policy)
#       }
#     ]
#   ])

#   user_group_map = {
#     for user_key, user in local.users : user_key => [
#       for g in user.groups :
#       trimspace(g)
#       if contains(var.group_names, trimspace(g))
#     ]
#   }
# }

locals {
  users_raw = csvdecode(file(var.user_csv_file))

  users = {
    for u in local.users_raw : u.username => {
      username = u.username
      policies = u.policies == "" ? [] : split(",", u.policies)
      groups   = u.groups   == "" ? [] : split(",", u.groups)
    }
  }

  user_policy_pairs = flatten([
    for user_key, user in local.users : [
      for policy in user.policies : {
        user_key   = user_key
        policy_key = trimspace(policy)
      }
    ]
  ])

  user_group_map = {
    for user_key, user in local.users :
    user_key => [
      for g in user.groups :
      trimspace(g)
      if contains(var.group_names, trimspace(g))
    ]
    if length(user.groups) > 0
  }
  
  group_users_map = {
    for group in distinct(flatten([for groups in local.user_group_map : groups])) :
    group => [
      for user, groups in local.user_group_map :
      user if contains(groups, group)
    ]
  }
}



resource "aws_iam_user" "this" {
  for_each = local.users

  name = each.value.username
  tags = var.common_tags
}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = {
    for pair in local.user_policy_pairs :
    "${pair.user_key}-${pair.policy_key}" => pair
  }

  user       = aws_iam_user.this[each.value.user_key].name
  policy_arn = var.policy_arns[each.value.policy_key]
}

resource "aws_iam_user_group_membership" "this" {
  for_each = local.user_group_map

  user   = aws_iam_user.this[each.key].name
  groups = each.value
}
