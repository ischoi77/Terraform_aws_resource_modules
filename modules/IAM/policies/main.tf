locals {
  # JSON 파일 목록 가져오기 (확장자 기준)
  json_files = fileset(var.policy_dir, "*.json")

  # 파일명에서 확장자 제거한 이름 추출
  policy_map = {
    for filename in local.json_files :
    trimsuffix(filename, ".json") => file("${var.policy_dir}/${filename}")
  }
}

resource "aws_iam_policy" "this" {
  for_each = local.policy_map

  name   = each.key
  policy = each.value
}
