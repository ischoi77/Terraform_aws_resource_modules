locals {
  processed_endpoints = {
    for ep_key, ep in var.vpc_endpoints : ep_key => {
      # VPC ID는 vpc_name으로 var.vpc_ids 매핑에서 조회
      vpc_id            = var.vpc_ids[ep.vpc_name]
      service_name      = ep.service_name
      vpc_endpoint_type = ep.vpc_endpoint_type

      # Gateway 유형이면 route_table_names를 이용하여 ID 리스트 생성, 없으면 null
      route_table_ids = ep.vpc_endpoint_type == "Gateway" ? (
        length(lookup(ep, "route_table_names", [])) > 0 ?
          [ for rt in lookup(ep, "route_table_names", []) : var.route_table_map[rt] ]
          : null
      ) : null

      # Interface 유형이면 subnet_names를 이용하여 ID 리스트 생성, 없으면 null
      subnet_ids = ep.vpc_endpoint_type == "Interface" ? (
        length(lookup(ep, "subnet_names", [])) > 0 ?
          [ for sn in lookup(ep, "subnet_names", []) : var.subnet_map[sn] ]
          : null
      ) : null

      # Interface 유형인 경우, 옵션으로 security_group_names를 이용하여 ID 리스트 생성, 없으면 null
      security_group_ids = ep.vpc_endpoint_type == "Interface" ? (
        length(lookup(ep, "security_group_names", [])) > 0 ?
          [ for sg in lookup(ep, "security_group_names", []) : var.security_group_map[sg] ]
          : null
      ) : null

      # Interface 유형인 경우 private_dns_enabled 값을 적용, 아니면 null
      private_dns_enabled = ep.vpc_endpoint_type == "Interface" ? ep.private_dns_enabled : null

      # 태그는 common_tags와 ep.tags를 merge하고 Name 태그는 엔드포인트 key로 설정
      tags = merge(var.common_tags, ep.tags, { "Name" = ep_key })
    }
  }
}

resource "aws_vpc_endpoint" "this" {
  for_each = local.processed_endpoints

  vpc_id            = each.value.vpc_id
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  route_table_ids   = each.value.route_table_ids
  subnet_ids        = each.value.subnet_ids
  security_group_ids = each.value.security_group_ids
  private_dns_enabled = each.value.private_dns_enabled

  tags = each.value.tags
}
