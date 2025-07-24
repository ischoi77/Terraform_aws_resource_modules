# locals {
#   # JSON 파일 목록 가져오기 (확장자 기준)
#   json_files = fileset(var.policy_dir, "*.json")

#   # 파일명에서 확장자 제거한 이름 추출
#   policy_map = {
#     for filename in local.json_files :
#     trimsuffix(filename, ".json") => file("${var.policy_dir}/${filename}")
#   }
# }

# resource "aws_iam_policy" "this" {
#   for_each = local.policy_map

#   name   = each.key
#   policy = each.value
# }

locals {
  user_policy_dir  = "${var.policy_dir}/user_policies"
  group_policy_dir = "${var.policy_dir}/group_policies"

  user_policy_files  = fileset(local.user_policy_dir, "*.json")
  group_policy_files = fileset(local.group_policy_dir, "*.json")

  user_policy_map = {
    for file in local.user_policy_files :
    trimsuffix(file, ".json") => file("${local.user_policy_dir}/${file}")
  }

  group_policy_map = {
    for file in local.group_policy_files :
    trimsuffix(file, ".json") => file("${local.group_policy_dir}/${file}")
  }
}

resource "aws_iam_policy" "user" {
  for_each = local.user_policy_map

  name   = each.key
  policy = each.value
}

resource "aws_iam_policy" "group" {
  for_each = local.group_policy_map

  name   = each.key
  policy = each.value
}
