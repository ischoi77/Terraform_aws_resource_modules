# locals {
#   # 외부 모듈에서 전달받은 igw_ids, ngw_ids, vpc_peering_ids 를 통합하여 gateway_map 을 생성합니다.
#   gateway_map = merge(var.igw_ids, var.ngw_ids, var.vpc_peering_ids)

#   # 각 route table의 각 routes 항목에 대해 ip_lists 파일을 읽어 destination CIDR 블록을 파싱하고,
#   # 지정된 gateway 값(키)를 local.gateway_map 에서 lookup 하여 gateway_id 를 할당합니다.
#   parsed_routes = flatten([
#     for rt_key, rt in var.route_tables : [
#       for route_item in rt.routes : [
#         for line in split("\n", trim(file("${path.root}/ip_lists/${route_item.route_key}.list"))) : {
#           route_table_key        = rt_key,
#           destination_cidr_block = trim(line),
#           gateway_id             = lookup(local.gateway_map, route_item.gateway, "")
#         }
#       ]
#     ]
#   ])
# }

# # 각 route table을 생성합니다.
# resource "aws_route_table" "this" {
#   for_each = var.route_tables

#   vpc_id = var.vpc_id

#   tags = merge(
#     var.common_tags,
#     each.value.tags,
#     { Name = each.value.name }
#   )
# }

# # ip_lists 파일의 각 라인마다 aws_route 리소스를 생성합니다.
# resource "aws_route" "this" {
#   for_each = { for idx, route in local.parsed_routes : "${route.route_table_key}-${idx}" => route }

#   route_table_id         = aws_route_table.this[each.value.route_table_key].id
#   destination_cidr_block = each.value.destination_cidr_block
#   gateway_id             = each.value.gateway_id
# }

# # 외부 모듈(module.subnets)에서 전달받은 subnet_ids map 에서 선택한 서브넷 이름을 lookup 하여
# # 각 route table에 대해 aws_route_table_association 리소스를 생성합니다.
# resource "aws_route_table_association" "this" {
#   for_each = {
#     for rt_key, rt in var.route_tables :
#     for idx, subnet_name in rt.subnets :
#       "${rt_key}-${idx}" => {
#         route_table_id = aws_route_table.this[rt_key].id,
#         subnet_id      = lookup(var.subnet_ids, subnet_name, "")
#       }
#   }

#   route_table_id = each.value.route_table_id
#   subnet_id      = each.value.subnet_id
# }

locals {
  gateway_map = var.igw_ids

  parsed_routes = flatten([
    for rt_key, rt in var.route_tables : [
      for route_item in rt.routes : [
        for line in split("\n", trimspace(file("${path.root}/ip_lists/${route_item.route_key}.list"))) : {
          route_table_key           = rt_key,
          destination_cidr_block    = trimspace(line),
          gateway_id = (length(regexall("peering", route_item.route_key)) > 0 ? null : (length(regexall("ngw", route_item.route_key)) > 0 ? null : lookup(local.gateway_map, route_item.gateway, ""))),
          nat_gateway_id = (length(regexall("ngw", route_item.route_key)) > 0 ? lookup(var.ngw_ids, route_item.gateway, "") : null),
          vpc_peering_connection_id = (length(regexall("peering", route_item.route_key)) > 0 ? lookup(var.vpc_peering_ids, route_item.gateway, "") : null)
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
      "${route.route_table_key}|${route.destination_cidr_block}|${coalesce(route.gateway_id, "")}|${coalesce(route.nat_gateway_id, "")}|${coalesce(route.vpc_peering_connection_id, "")}"
    ) => route
  }

  route_table_id         = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block = each.value.destination_cidr_block

  gateway_id                = each.value.gateway_id
  nat_gateway_id            = each.value.nat_gateway_id
  vpc_peering_connection_id = each.value.vpc_peering_connection_id
}


# 서브넷 연결 정보를 담은 로컬 변수를 이용하여 aws_route_table_association 리소스를 생성
resource "aws_route_table_association" "this" {
  for_each = { for assoc in local.route_table_associations : assoc.key => assoc }

  route_table_id = each.value.route_table_id
  subnet_id      = each.value.subnet_id
}
