resource "aws_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  # var.vpc_ids에서 vpc_name으로 VPC ID 조회
  vpc_id       = var.vpc_ids[each.value.vpc_name]
  service_name = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # Gateway 엔드포인트: route_table_names 사용
  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? (
    lookup(each.value, "route_table_names", []) != [] ?
      [ for rt_name in each.value.route_table_names : var.route_table_map[rt_name] ]
      : null
  ) : null

  # Interface 엔드포인트: subnet_names 사용
  subnet_ids = each.value.vpc_endpoint_type == "Interface" ? (
    lookup(each.value, "subnet_names", []) != [] ?
      [ for subnet_name in each.value.subnet_names : var.subnet_map[subnet_name] ]
      : null
  ) : null

  # Interface 엔드포인트: 옵션으로 security_group_names 사용 (값이 없으면 null 처리)
  security_group_ids = each.value.vpc_endpoint_type == "Interface" ? (
    lookup(each.value, "security_group_names", []) != [] ?
      [ for sg_name in each.value.security_group_names : var.security_group_map[sg_name] ]
      : null
  ) : null

  private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? each.value.private_dns_enabled : null

  tags = merge(
    var.common_tags,
    each.value.tags,
    { "Name" = each.key }
  )
}
