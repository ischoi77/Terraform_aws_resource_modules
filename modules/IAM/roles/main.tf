locals {
  roles_raw = csvdecode(file(var.roles_csv_file))

  roles = {
    for r in local.roles_raw : r.role_name => {
      name         = r.role_name
      assume_file  = r.assume_policy_file
      description  = try(r.description, null)
      policy_names = r.policies == "" ? [] : split(",", r.policies)
      tags = (
        r.tags == "" ? {} :
        {
          for pair in split(";", r.tags) :
          trimspace(split("=", pair)[0]) => trimspace(split("=", pair)[1])
        }
      )
    #   inline_policies  = r.inline_policies  == "" ? [] : split(",", r.inline_policies)
    }
  }

  all_policy_arns = merge(
    var.managed_policy_arns,
    var.managed_service_role_policy_arns,
    var.custom_policy_arns
  )

  # Role → 경로
  assume_policy_paths = {
    for role_name, role in local.roles :
    role_name => "${path.root}/assume_role_policy_files/${trimspace(role.assume_file)}.json"
  }

  # 파일 존재 여부 확인
  roles_with_policy_file = {
    for role_name, role in local.roles :
    role_name => merge(role, {
      assume_policy_path = local.assume_policy_paths[role_name]
    })
    if fileexists(local.assume_policy_paths[role_name])
  }


#   inline_policy_map = {
#     for role_name, role in local.roles_with_policy_file :
#     for policy_name in role.inline_policies :
#     "${role_name}::${trimspace(policy_name)}" => {
#       role_name   = role_name
#       policy_name = trimspace(policy_name)
#       policy_json = var.inline_policies[trimspace(policy_name)]
#     }
#   }

  role_policy_attachments = {
    for attachment in flatten([
      for role_key, role in local.roles : [
        for policy_name in role.policy_names : {
          key        = "${role_key}::${policy_name}"
          role_key  = role_key
          policy_arn = lookup(local.all_policy_arns, policy_name, null)
        }
      ]
    ]) : attachment.key => attachment
  }
}


resource "aws_iam_role" "this" {
  for_each = local.roles_with_policy_file

  name               = each.key
  assume_role_policy = file(each.value.assume_policy_path)
  description        = each.key
  tags = merge(var.common_tags, each.value.tags)
}


# resource "aws_iam_role_policy" "inline" {
#   for_each = local.inline_policy_map

#   name   = each.value.policy_name
#   role   = aws_iam_role.this[each.value.role_name].name
#   policy = each.value.policy_json
# }

resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.role_policy_attachments

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}