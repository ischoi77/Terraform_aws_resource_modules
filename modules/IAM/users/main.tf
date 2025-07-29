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

  # parse_tags = function(tag_str) {
  #   tag_str == "" ? {} :
  #   {
  #     for pair in split(";", tag_str) :
  #     trimspace(split("=", pair)[0]) => trimspace(split("=", pair)[1])
  #   }
  # }

  users = {
    for u in local.users_raw : u.username => {
      username = u.username
      policies = u.policies == "" ? [] : split(",", u.policies)
      groups   = u.groups   == "" ? [] : split(",", u.groups)
      tags = (
        u.tags == "" ? {} :
        {
          for pair in split(";", u.tags) :
          trimspace(split("=", pair)[0]) => trimspace(split("=", pair)[1])
        }
      )
    }
  }

  all_policy_arns = merge(
    var.managed_policy_arns,
    var.custom_policy_arns
  )



  user_policy_attachments = {
    for attachment in flatten([
      for user_key, user in local.users : [
        for policy_name in user.policies : {
          key        = "${user_key}::${policy_name}"
          user_key  = user_key
          policy_arn = lookup(local.all_policy_arns, policy_name, null)
        }
      ]
    ]) : attachment.key => attachment
  }

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
  tags = merge(var.common_tags, each.value.tags)

}

resource "aws_iam_user_policy_attachment" "this" {
  for_each = local.user_policy_attachments

  user       = aws_iam_user.this[each.value.user_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_user_group_membership" "this" {
  for_each = local.user_group_map

  user   = aws_iam_user.this[each.key].name
  groups = each.value
}
