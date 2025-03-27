locals {
  # 모듈 루트 하위의 vpc_sg_rules 폴더 내 모든 CSV 파일 검색
  sg_rule_files = fileset("${path.module}/vpc_sg_rules", "**/*.csv")

  # 각 CSV 파일의 경로 정보를 파싱하여 보안그룹 데이터 생성
  sg_data = {
    for file_path in local.sg_rule_files : 
    # 파일 경로 예시: "vpc_sg_rules/<vpc_name>/<sg_name>.csv"
    # split("/") 결과: [ "<vpc_name>", "<sg_name>.csv" ]
    "${element(split("/", file_path), 0)}_${replace(element(split("/", file_path), 1), ".csv", "")}" => {
      vpc     = element(split("/", file_path), 0)
      sg_name = replace(element(split("/", file_path), 1), ".csv", "")
      rules   = csvdecode(file("${path.module}/vpc_sg_rules/${file_path}"))
    }
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
}

locals {
  sg_rules_flat = flatten([
    for sg_key, sg in local.sg_data : [
      for idx, rule in sg.rules : {
        sg_key = sg_key
        idx    = idx
        rule   = rule
        // Rule_Description 항목을 제외하고, SG_ID_or_CIDR 키를 사용하여 md5 해시를 생성합니다.
        rule_id = md5(
          "${sg_key}-${idx}-${rule.Direction}-${rule.Protocol}-${rule.Port}-${rule["SG_ID_or_CIDR"]}"
        )
      }
    ]
  ])
}



resource "aws_security_group_rule" "this" {
  for_each = { for r in local.sg_rules_flat : r.rule_id => r }

  security_group_id = aws_security_group.this[each.value.sg_key].id
  type              = lower(each.value.rule.Direction)  # "ingress" 또는 "egress"
  protocol          = each.value.rule.Protocol
  from_port         = tonumber(each.value.rule.Port)
  to_port           = tonumber(each.value.rule.Port)

  cidr_blocks = length(regexall("/", each.value.rule["SG_ID_or_CIDR"])) > 0 ? [each.value.rule["SG_ID_or_CIDR"]] : []
  source_security_group_id = length(regexall("/", each.value.rule["SG_ID_or_CIDR"])) > 0 ? null : each.value.rule["SG_ID_or_CIDR"]

  description = trimspace(each.value.rule.Rule_Description) != "" ? each.value.rule.Rule_Description : ""
}
