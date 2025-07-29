# locals {
#   roles_raw = csvdecode(file(var.roles_csv_file))

#   roles = {
#     for r in local.roles_raw : r.role_name => {
#       managed_policies = r.managed_policies == "" ? [] : split(",", r.managed_policies)
#       inline_policies  = r.inline_policies  == "" ? [] : split(",", r.inline_policies)
#     }
#   }

#   # assume_role_policy_file path: ./assume_role_policy_files/<role>.json
#   assume_role_policies = {
#     for role_name in keys(local.roles) :
#     role_name => file("${path.root}/assume_role_policy_files/${role_name}.json")
#   }

#   inline_policy_map = {
#     for role_name, role in local.roles :
#     for policy_name in role.inline_policies :
#     "${role_name}::${trimspace(policy_name)}" => {
#       role_name   = role_name
#       policy_name = trimspace(policy_name)
#       policy_json = var.inline_policies[trimspace(policy_name)]
#     }
#   }

#   managed_policy_map = {
#     for role_name, role in local.roles :
#     for policy_name in role.managed_policies :
#     "${role_name}::${trimspace(policy_name)}" => {
#       role_name  = role_name
#       policy_arn = var.managed_policy_arns[trimspace(policy_name)]
#     }
#   }
# }

locals {
  roles_raw = csvdecode(file(var.roles_csv_file))

  parse_tags = function(tag_str) {
    tag_str == "" ? {} :
    {
      for pair in split(";", tag_str) :
      trimspace(split("=", pair)[0]) => trimspace(split("=", pair)[1])
    }
  }

  roles = {
    for r in local.roles_raw : r.role_name => {
      assume_file      = r.assume_policy_file
      managed_policies = r.managed_policies == "" ? [] : split(",", r.managed_policies)
      tags              = local.parse_tags(r.tags)
    #   inline_policies  = r.inline_policies  == "" ? [] : split(",", r.inline_policies)
    }
  }



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

  managed_policy_pairs = flatten([
    for role_name, role in local.roles_with_policy_file : [
      for policy_name in role.managed_policies : {
        key        = "${role_name}::${trimspace(policy_name)}"
        role_name  = role_name
        policy_arn = var.managed_policy_arns[trimspace(policy_name)]
      }
    ]
  ])

  managed_policy_map = {
    for item in local.managed_policy_pairs :
    item.key => {
      role_name  = item.role_name
      policy_arn = item.policy_arn
    }
  }
}


resource "aws_iam_role" "this" {
  for_each = local.roles_with_policy_file

  name               = each.key
  assume_role_policy = file(each.value.assume_policy_path)
  tags               = var.common_tags
}


# resource "aws_iam_role_policy" "inline" {
#   for_each = local.inline_policy_map

#   name   = each.value.policy_name
#   role   = aws_iam_role.this[each.value.role_name].name
#   policy = each.value.policy_json
# }

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.managed_policy_map

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = each.value.policy_arn
}
