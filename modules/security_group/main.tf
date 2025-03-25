/*
Title: SPCv2 Security_Group module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/



# 1. 보안 그룹 자체를 생성
resource "aws_security_group" "this" {
  for_each    = var.security_groups

  name        = each.key
  description = each.value.description
  vpc_id      = var.vpc_ids[each.value.vpc_name]

  tags = merge(
    var.common_tags,
    each.value.tags
  )
}

# 2. locals 블록에서 각 보안 그룹의 rule 리스트를 평면화하여 변환
locals {
  # 인바운스 규칙 평면화
  ingress_rules_list = flatten([
    for sg_name, sg in var.security_groups : [
      for idx, rule in sg.ingress : {
         id                = "${sg_name}-ingress-${idx}"
         security_group_id = aws_security_group.this[sg_name].id
         from_port         = tonumber(rule[0])
         to_port           = tonumber(rule[1])
         protocol          = rule[2]
         # 만약 rule 리스트의 마지막 항목이 "desc:" 접두어로 시작하면 description 으로 사용
         description       = (length(rule) > 3 && startswith(rule[length(rule)-1], "desc:")) ? substr(rule[length(rule)-1], 5, length(rule[length(rule)-1]) - 5) : "" 
         cidr_blocks       = (length(rule) > 3 && startswith(rule[length(rule)-1], "desc:")) ? slice(rule, 3, length(rule)-1) : slice(rule, 3, length(rule))
      }
    ]
  ])
  ingress_rules = { for rule in local.ingress_rules_list : rule.id => rule }

  # 아웃바운드 규칙 평면화
  egress_rules_list = flatten([
    for sg_name, sg in var.security_groups : [
      for idx, rule in sg.egress : {
         id                = "${sg_name}-egress-${idx}"
         security_group_id = aws_security_group.this[sg_name].id
         from_port         = tonumber(rule[0])
         to_port           = tonumber(rule[1])
         protocol          = rule[2]
         description       = (length(rule) > 3 && startswith(rule[length(rule)-1], "desc:")) ? substr(rule[length(rule)-1], 5, length(rule[length(rule)-1]) - 5) : ""
         cidr_blocks       = (length(rule) > 3 && startswith(rule[length(rule)-1], "desc:")) ? slice(rule, 3, length(rule)-1) : slice(rule, 3, length(rule))
      }
    ]
  ])
  egress_rules = { for rule in local.egress_rules_list : rule.id => rule }
}

# 3. aws_security_group_rule 리소스를 별도로 생성 (ingress)
resource "aws_security_group_rule" "ingress" {
  for_each = local.ingress_rules

  type              = "ingress"
  security_group_id = each.value.security_group_id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description != "" ? each.value.description : null
}

# 4. aws_security_group_rule 리소스를 별도로 생성 (egress)
resource "aws_security_group_rule" "egress" {
  for_each = local.egress_rules

  type              = "egress"
  security_group_id = each.value.security_group_id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = each.value.cidr_blocks
  description       = each.value.description != "" ? each.value.description : null
}
