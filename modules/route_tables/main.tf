
locals {


  # parsed_routes = flatten([
  #   for rt_key, rt in var.route_tables : [
  #     for route_item in rt.routes : [
  #       for line in split("\n", trimspace(file("${path.root}/ip_lists/${route_item.route_key}.list"))) : {
  #         route_table_key           = rt_key,
  #         destination_cidr_block    = trimspace(line),
  #         gateway_id = (
  #           length(regexall("peering", route_item.gateway)) > 0 ? null :
  #           length(regexall("ngw", route_item.gateway)) > 0 ? null :
  #           lookup(var.igw_ids, route_item.gateway, "")
  #         ),
  #         nat_gateway_id = (
  #           length(regexall("ngw", route_item.gateway)) > 0 ?
  #           lookup(var.ngw_ids, route_item.gateway, "") : null
  #         ),
  #         vpc_peering_connection_id = (
  #           length(regexall("peering", route_item.gateway)) > 0 ?
  #           lookup(var.vpc_peering_ids, route_item.gateway, "") : null
  #         )
  #       }
  #     ]
  #   ]
  # ])

    # 미리 각 route 항목에 대해 고유한 key를 계산합니다.
  preprocessed_routes = flatten([
    for rt_key, rt in var.route_tables : [
      for route_item in rt.routes : [
        for line in split("\n", trimspace(file("${path.root}/ip_lists/${route_item.route_key}.list"))) : {
          # md5 키는 정적인 값만 사용 (인덱스 미사용)
          key = md5(
            "${rt_key}|${route_item.route_key}|${route_item.gateway}|${trimspace(line)}"
          ),

          
          route_table_key        = rt_key,
          destination_cidr_block = trimspace(line),
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
  # preprocessed_routes 리스트를 key로 매핑한 map으로 변환 (이 map의 키는 모두 입력 변수에 기반하므로 결정적입니다)
  parsed_routes_map = { for route in local.preprocessed_routes : route.key => route }

  # 각 route table에 대한 서브넷 연결 정보를 생성하기 위해,
  # var.route_tables의 각 서브넷 이름을 외부 모듈의 subnet_ids map에서 lookup 하여 고유한 key를 부여합니다.
  route_table_associations = flatten([
    for rt_key, rt in var.route_tables : [
      for subnet_name in rt.subnets : {
        # 여기서는 입력 변수에 기반한 rt_key와 subnet_name을 키로 사용합니다.
        key            = "${rt_key}-${subnet_name}",
        route_table_key = rt_key,
        subnet_name    = subnet_name
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
  for_each = local.parsed_routes_map

  route_table_id         = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
}


# 서브넷 연결 정보를 담은 로컬 변수를 이용하여 aws_route_table_association 리소스를 생성
resource "aws_route_table_association" "this" {
  for_each = { for assoc in local.route_table_associations : assoc.key => assoc }

  route_table_id = aws_route_table.this[each.value.route_table_key].id
  subnet_id      = lookup(var.subnet_ids, each.value.subnet_name, "")
}
