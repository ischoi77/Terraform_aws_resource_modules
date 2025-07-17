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
  // 키는 "<vpc_id>_<SG_Name>" 형식으로 생성
  sg_lookup = {
    for sg_key, sg in local.sg_data :
    sg.sg_name => aws_security_group.this[sg_key].id
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

#v3.40
# resource "aws_security_group_rule" "this" {
#   for_each = local.unique_sg_rules

#   security_group_id = aws_security_group.this[each.value.sg_key].id

#   // Direction: inbound => ingress, outbound => egress
#   type     = lower(each.value.rule.Direction) == "inbound" ? "ingress" : "egress"
#   protocol = each.value.rule.Protocol

#   // Port 처리: 단일 값 또는 범위(예: "8000-8080") 구분
#   from_port = (
#     length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
#     tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 0)) :
#     tonumber(each.value.rule.Port)
#   )

#   to_port = (
#     length(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)) > 0 ?
#     tonumber(element(regexall("^(\\d+)-(\\d+)$", each.value.rule.Port)[0], 1)) :
#     tonumber(each.value.rule.Port)
#   )

#   // SG_ID_or_CIDR 처리:
#   // 1. "/" 포함 → CIDR 블록 사용 (source_security_group_id는 null)
#   // 2. "/" 미포함 → 값이 "<sg->" 형식이면 그대로 사용,
#   // 3. 그렇지 않으면 해당 값을 SG_Name으로 간주하여 lookup 수행 (VPC와 상관없이)
#   // CIDR vs. SG_ID vs. self 처리 순서
#   #cidr_blocks = each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null : length(regexall("/", each.value.rule["SG_ID_or_CIDR"])) > 0 ? [each.value.rule["SG_ID_or_CIDR"]] : null
#   cidr_blocks = each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ? [each.value.rule["SG_ID_or_CIDR"]] : null
#   #source_security_group_id = each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null : (length(regexall("/", each.value.rule["SG_ID_or_CIDR"])) > 0 ? null : (startswith(each.value.rule["SG_ID_or_CIDR"], "<sg->") ? each.value.rule["SG_ID_or_CIDR"] : lookup(local.sg_lookup, each.value.rule["SG_ID_or_CIDR"], null)))
#   source_security_group_id = each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ? null :  (startswith(each.value.rule["SG_ID_or_CIDR"], "<sg->") || can(regex("^[0-9]+/sg-[0-9a-fA-F]+$", each.value.rule["SG_ID_or_CIDR"]))) ? each.value.rule["SG_ID_or_CIDR"] : lookup(local.sg_lookup, each.value.rule["SG_ID_or_CIDR"], null)

#   // Rule_Description 항목이 비어있을 경우 빈 문자열로 처리
#   description = trimspace(each.value.rule.Rule_Description) != "" ? each.value.rule.Rule_Description : ""
#   lifecycle {
#     ignore_changes = [ description ]
#   }
# }


resource "aws_security_group_rule" "this" {
  for_each = local.unique_sg_rules

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

  # self 속성을 항상 제공: self 룰일 땐 true, 아니면 false
  self = each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key

  cidr_blocks = (
    each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null :
    can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ? [each.value.rule["SG_ID_or_CIDR"]] :
    null
  )

  source_security_group_id = (
    each.value.rule["SG_ID_or_CIDR"] == each.value.sg_key ? null :
    can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", each.value.rule["SG_ID_or_CIDR"])) ? null :
    (
      startswith(each.value.rule["SG_ID_or_CIDR"], "<sg->") ||
      can(regex("^[0-9]+/sg-[0-9a-fA-F]+$", each.value.rule["SG_ID_or_CIDR"]))
    ) ? each.value.rule["SG_ID_or_CIDR"] :
    lookup(local.sg_lookup, each.value.rule["SG_ID_or_CIDR"], null)
  )

  description = trimspace(each.value.rule.Rule_Description) != "" ? each.value.rule.Rule_Description : ""
}
