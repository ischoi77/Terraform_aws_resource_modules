locals {
  # 모듈 루트 하위의 vpc_sg_rules 폴더 내 모든 CSV 파일 검색
  sg_rule_files = fileset("${path.root}/vpc_sg_rules", "**/*.csv")

  # 각 CSV 파일의 경로 정보를 파싱하여 보안그룹 데이터 생성
  sg_data = {
    for file_path in local.sg_rule_files : 
    # 파일 경로 예시: "vpc_sg_rules/<vpc_name>/<sg_name>.csv"
    # split("/") 결과: [ "<vpc_name>", "<sg_name>.csv" ]
    "${element(split("/", file_path), 0)}_${replace(element(split("/", file_path), 1), ".csv", "")}" => {
      vpc     = element(split("/", file_path), 0)
      sg_name = replace(element(split("/", file_path), 1), ".csv", "")
      rules   = csvdecode(file("${path.root}/vpc_sg_rules/${file_path}"))
    }
  }
  sg_rules_flat = flatten([
    for sg_key, sg in local.sg_data : [
      for rule in sg.rules : {
        sg_key  = sg_key
        rule    = rule
        // idx 없이 rule_id 생성: sg_name과 나머지 속성으로 고유 식별자 생성
        rule_id = "${sg.sg_name}-${md5("${sg_key}-${rule.Direction}-${rule.Protocol}-${rule.Port}-${rule["SG_ID_or_CIDR"]}")}"
      }
    ]
  ])

    // 중복된 rule_id가 있을 경우 그룹화하여 각 그룹의 첫 번째 항목만 사용
  unique_sg_rules = { for k, v in { for r in local.sg_rules_flat : r.rule_id => r ... } : k => v[0] }
     // 동일 모듈 내에서 생성한 Security Group 의 SG_ID lookup mapping 생성  

  self_rules = {
    for id, r in local.unique_sg_rules :
    id => r
    if r.rule["SG_ID_or_CIDR"] == r.sg_key
  }
  other_rules = {
    for id, r in local.unique_sg_rules :
    id => r
    if r.rule["SG_ID_or_CIDR"] != r.sg_key
  }


  // 키는 "<vpc_id>_<SG_Name>" 형식으로 생성
  sg_lookup = {
    for sg_key, sg in local.sg_data :
    sg_key => aws_security_group.this[sg_key].id
  }

  # 순수 SG_Name → sg_key("<vpc>_<sg_name>") 변환용 매핑
  sg_name_to_key = {
    for sg_key, sg in local.sg_data :
    sg.sg_name => sg_key
  }
}

resource "aws_security_group" "this" {
  for_each = local.sg_data

  name        = each.value.sg_name
  description = "Security Group for ${each.value.sg_name}"
  vpc_id      = lookup(var.vpc_ids, each.value.vpc)

  tags = merge(
    var.common_tags,
    {
      "Name" = each.value.sg_name
    }
  )
  lifecycle {
    ignore_changes = [ description ]
  }
}


# 1) self == true 전용
resource "aws_security_group_rule" "self" {
  for_each = local.self_rules

  security_group_id = aws_security_group.this[each.value.sg_key].id
  type              = lower(each.value.rule.Direction) == "inbound" ? "ingress" : "egress"
  protocol          = each.value.rule.Protocol

  from_port = (
    length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
      tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 0)) :
      tonumber(each.value.rule.Port)
  )
  to_port = (
    length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
      tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 1)) :
      tonumber(each.value.rule.Port)
  )

  self        = true
  description = trimspace(each.value.rule.Rule_Description) != "" ? each.value.rule.Rule_Description : ""
}

# 2) CIDR / SG ID / Peering 룰 전용
resource "aws_security_group_rule" "others" {
  for_each         = local.other_rules
  security_group_id = aws_security_group.this[each.value.sg_key].id
  type              = lower(each.value.rule.Direction) == "inbound" ? "ingress" : "egress"
  protocol          = each.value.rule.Protocol

  from_port = (
    length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
      tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 0)) :
      tonumber(each.value.rule.Port)
  )
  to_port = (
    length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
      tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 1)) :
      tonumber(each.value.rule.Port)
  )

  cidr_blocks = (
    can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ?
      [each.value.rule["SG_ID_or_CIDR"]] :
      null
  )

  source_security_group_id = (
    # 1) CIDR 이면 null
    can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ? null :

    # 2) '<sg->...' 형식이나 '123456789012/sg-...' 형식이면 그대로 사용
    (
      startswith(each.value.rule["SG_ID_or_CIDR"], "<sg->") ||
      can(regex("^[0-9]+/sg-[0-9a-fA-F]+$", each.value.rule["SG_ID_or_CIDR"]))
    ) ? each.value.rule["SG_ID_or_CIDR"] :

    # 3) 그 외는 순수 SG_Name 이므로, 먼저 sg_name_to_key 로 key 로 변환한 뒤 lookup
    lookup(
      local.sg_lookup,
      local.sg_name_to_key[each.value.rule["SG_ID_or_CIDR"]],
      null
    )
  )
  description = trimspace(each.value.rule.Rule_Description) != "" ? each.value.rule.Rule_Description : ""
}
