locals {
  # 설정된 디렉토리에서 JSON 정책 파일 수집
  policy_files = fileset(var.policies.policy_dir, "*.json")

  all_policy_map = {
    for file in local.policy_files :
    trimsuffix(file, ".json") => {
      name   = trimsuffix(file, ".json")
      path   = "${var.policies.policy_dir}/${file}"
      policy = file("${var.policies.policy_dir}/${file}")
    }
  }

  # AWS 관리형 정책들과 충돌하지 않는 사용자 정의 정책만 필터링
  # custom_policy_map = {
  #   for name, v in local.all_policy_map : name => v if not (name in var.policies.managed_policy_names || name in var.policies.managed_service_role_policy_names)
  # }
  custom_policy_map = {
    for name, v in local.all_policy_map :
    name => v if !(
      name in var.policies.managed_policy_names || 
      name in var.policies.managed_service_role_policy_names
    )
  }
  
  skipped_policy_names = [
    for name in keys(local.all_policy_map) :
    name if name in var.policies.managed_policy_names || name in var.policies.managed_service_role_policy_names
  ]

  managed_policy_arns = {
    for name in var.policies.managed_policy_names :
    name => "arn:aws:iam::aws:policy/${name}"
  }

  managed_service_role_policy_arns = {
    for name in var.policies.managed_service_role_policy_names :
    name => "arn:aws:iam::aws:policy/aws-service-role/${name}"
  }
}

resource "aws_iam_policy" "this" {
  for_each = local.custom_policy_map

  name   = each.value.name
  policy = each.value.policy
}
