
locals {

  parsed_routes = flatten([
    for rt_key, rt in var.route_tables : [
      for route_item in rt.routes : [
        for line in split("\n", trimspace(file("${path.root}/ip_lists/${route_item.route_key}.list"))) : {
          route_table_key           = rt_key,
          destination_cidr_block    = trimspace(line),
          gateway_id = (
            length(regexall("peering", route_item.gateway)) > 0 ? null :
            length(regexall("ngw", route_item.gateway)) > 0 ? null :
            lookup(var.igw_ids, route_item.gateway, "")
          ),
          nat_gateway_id = (
            length(regexall("ngw", route_item.gateway)) > 0 ?
            lookup(var.ngw_ids, route_item.gateway, "") : null
          ),
          vpc_peering_connection_id = (
            length(regexall("peering", route_item.gateway)) > 0 ?
            lookup(var.vpc_peering_ids, route_item.gateway, "") : null
          )
        }
      ]
    ]
  ])

  # 각 route table에 대한 서브넷 연결 정보를 생성하기 위해,
  # var.route_tables의 각 서브넷 이름을 외부 모듈의 subnet_ids map에서 lookup 하여 고유한 key를 부여합니다.
  route_table_associations = flatten([
    for rt_key, rt in var.route_tables : [
      for idx, subnet_name in rt.subnets : {
        key             = "${rt_key}-${idx}"
        route_table_id  = aws_route_table.this[rt_key].id
        subnet_id       = lookup(var.subnet_ids, subnet_name, "")
      }
    ]
  ])
}

# 각 route table 생성
resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = lookup(var.vpc_ids, each.value.vpc_name, "")

  tags = merge(
    var.common_tags,
    each.value.tags,
    { Name = each.value.name }
  )
}

# ip_lists 파일의 각 라인마다 aws_route 리소스를 생성
resource "aws_route" "this" {
  for_each = {
    for route in local.parsed_routes :
    md5(
      "${route.route_table_key}|${route.destination_cidr_block}|${(route.gateway_id != null ? route.gateway_id : "")}|${(route.nat_gateway_id != null ? route.nat_gateway_id : "")}|${(route.vpc_peering_connection_id != null ? route.vpc_peering_connection_id : "")}"
    ) => route
  }

  route_table_id         = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
  depends_on = [ aws_route_table.this ]
}


# 서브넷 연결 정보를 담은 로컬 변수를 이용하여 aws_route_table_association 리소스를 생성
resource "aws_route_table_association" "this" {
  for_each = { for assoc in local.route_table_associations : assoc.key => assoc }

  route_table_id = each.value.route_table_id
  subnet_id      = each.value.subnet_id
}
