locals {
  policy_dir = var.policies.policy_dir

  user_policy_dir  = "${local.policy_dir}/user_policies"
  group_policy_dir = "${local.policy_dir}/group_policies"
  role_policy_dir  = "${local.policy_dir}/role_policies"

  user_policy_files  = fileset(local.user_policy_dir, "*.json")
  group_policy_files = fileset(local.group_policy_dir, "*.json")
  role_policy_files  = fileset(local.role_policy_dir, "*.json")

  user_policy_map = {
    for file in local.user_policy_files :
    trimsuffix(file, ".json") => file("${local.user_policy_dir}/${file}")
  }

  group_policy_map = {
    for file in local.group_policy_files :
    trimsuffix(file, ".json") => file("${local.group_policy_dir}/${file}")
  }

  role_policy_map = {
    for file in local.role_policy_files :
    trimsuffix(file, ".json") => file("${local.role_policy_dir}/${file}")
  }

  aws_user_policy_names  = try(var.policies.user.aws_managed, [])
  aws_group_policy_names = try(var.policies.group.aws_managed, [])
  aws_role_policy_names  = try(var.policies.role.aws_managed, [])
}

resource "aws_iam_policy" "user" {
  for_each = local.user_policy_map
  name     = each.key
  policy   = each.value
}

resource "aws_iam_policy" "group" {
  for_each = local.group_policy_map
  name     = each.key
  policy   = each.value
}

data "aws_iam_policy" "aws_managed_user" {
  for_each = toset(local.aws_user_policy_names)
  name     = each.key
}

data "aws_iam_policy" "aws_managed_group" {
  for_each = toset(local.aws_group_policy_names)
  name     = each.key
}

data "aws_iam_policy" "aws_managed_role" {
  for_each = toset(local.aws_role_policy_names)
  name     = each.key
}
