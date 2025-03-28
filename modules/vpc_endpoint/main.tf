
resource "aws_vpc_endpoint" "this" {
  for_each = var.vpc_endpoints

  vpc_id            = var.vpc_ids[each.value.vpc_name]
  service_name      = each.value.service_name
  vpc_endpoint_type = each.value.vpc_endpoint_type

  # Gateway 엔드포인트인 경우: route_table_names로 lookup
  route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? (
    contains(each.value, "route_table_names") ?
      [ for rt_name in each.value.route_table_names : var.route_table_map[rt_name] ]
      : null
  ) : null

  # Interface 엔드포인트인 경우: subnet_names로 lookup
  subnet_ids = each.value.vpc_endpoint_type == "Interface" ? (
    contains(each.value, "subnet_names") ?
      [ for subnet_name in each.value.subnet_names : var.subnet_map[subnet_name] ]
      : null
  ) : null

  # Interface 엔드포인트인 경우: security_group_names로 lookup (옵션)
  security_group_ids = each.value.vpc_endpoint_type == "Interface" ? (
    contains(each.value, "security_group_names") && length(each.value.security_group_names) > 0 ?
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
