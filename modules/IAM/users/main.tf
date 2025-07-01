locals {
  users_raw = csvdecode(file(var.user_csv_file))

  users = {
    for u in local.users_raw : u.username => {
      username = u.username
      policies = split(",", u.policies)
    }
  }

  # 사용자-정책 조합 (username + policy)
  user_policy_pairs = flatten([
    for user_key, user in local.users : [
      for policy in user.policies : {
        user_key   = user_key
        policy_key = trimspace(policy)  # 공백 제거
      }
    ]
  ])
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
