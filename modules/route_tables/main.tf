/*
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-03-26
Description: AWS Route 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v3.0.0
*/


locals {
  ############################################
  # 1) CSV 파일 읽어서 객체 리스트로 변환
  ############################################
  route_csv = csvdecode(file(var.routes_csv_file))

  # 고유한 table_name(key) 목록
  distinct_tables = distinct([for r in local.route_csv : r.table_name])

  # 각 table_name 별로 라우팅 항목(route_key, gateway, vpc_name)을 묶어둠
  routes_by_table = {
    for tbl in local.distinct_tables :
    tbl => [
      # 올바른 리스트 내포식 문법: 먼저 "for row in local.route_csv :" 
      # 다음에 생성할 객체, 마지막에 "if …" 
      for row in local.route_csv : 
      {
        route_key = row.route_list
        gateway   = row.gateway
        vpc_name  = row.vpc_name
      }
      if row.table_name == tbl
    ]
  }

  ############################################
  # 2) parsed_routes: 실제 aws_route 생성에 필요한 속성 목록
  ############################################
  parsed_routes_raw = flatten([
    for rt_key, rt_info in var.route_tables : [
      for item in lookup(local.routes_by_table, rt_key, []) : (
          # endpoint 모드
          item.route_key == "endpoint" ?
          [
            {
              route_table_key        = rt_key,
              destination_cidr_block = null,
              vpc_endpoint_id      = item.gateway,
              gateway_id             = null,
              nat_gateway_id         = null,
              vpc_peering_connection_id = null
            }
          ]
          :
          # 기존대로 파일 읽기 
          [ for line in split("\n", trimspace(file("${path.root}/ip_lists/${item.route_key}.list"))) : {
              # md5 키는 정적인 값만 사용 (인덱스 미사용)
            key = md5(
              "${rt_key}|${item.route_key}|${item.gateway}|${trimspace(line)}"
            ),
            route_table_key           = rt_key,
            destination_cidr_block    = trimspace(line),
            vpc_endpoint_id           = null,
            #gateway    = item.gateway,
            #route_key  = item.route_key,
            gateway_id = (
              length(regexall("peering", item.gateway)) > 0 ? null :
              length(regexall("ngw",     item.gateway)) > 0 ? null :
              lookup(var.igw_ids, item.gateway, "")
            ),
            nat_gateway_id = (
              length(regexall("ngw", item.gateway)) > 0 ?
              lookup(var.ngw_ids, item.gateway, "") : null
            ),
            vpc_peering_connection_id = (
              length(regexall("peering", item.gateway)) > 0 ?
              lookup(var.vpc_peering_ids, item.gateway, "") : null
            )
          }
        ]
      )
    ]
  ])
 preprocessed_routes = { for route in local.parsed_routes_raw : route.key => route if route.vpc_endpoint_id == null}


  ############################################
  # 3) Route Table <-> Subnet Association 정보
  ############################################
  route_table_associations = flatten([
    for rt_key, rt_info in var.route_tables : [
      for subnet_name in rt_info.subnets : {
        key             = "${rt_key}-${subnet_name}",
        route_table_key = rt_key,
        subnet_name     = subnet_name
      }
    ]
  ])

  endpoint_associations = flatten([
    for rt_key, rt_info in var.route_tables : [
      for item in lookup(local.routes_by_table, rt_key, []) :
        item.route_key == "endpoint" ? [
          {
            key               = "${rt_key}-${item.gateway}"
            route_table_key   = rt_key
            vpc_endpoint_name = item.gateway
          }
        ] : []
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
    { Name = each.key }
  )
}

# ip_lists 파일의 각 라인마다 aws_route 리소스를 생성
resource "aws_route" "this" {
  #for_each = local.parsed_routes_map
  for_each = local.preprocessed_routes

  route_table_id             = aws_route_table.this[each.value.route_table_key].id
  destination_cidr_block     = each.value.destination_cidr_block

  gateway_id                 = each.value.gateway_id
  nat_gateway_id             = each.value.nat_gateway_id
  vpc_peering_connection_id  = each.value.vpc_peering_connection_id
}


# 서브넷 연결 정보를 담은 로컬 변수를 이용하여 aws_route_table_association 리소스를 생성
resource "aws_route_table_association" "this" {
  for_each = { for assoc in local.route_table_associations : assoc.key => assoc }

  route_table_id = aws_route_table.this[each.value.route_table_key].id
  subnet_id      = lookup(var.subnet_ids, each.value.subnet_name, "")
}


resource "aws_vpc_endpoint_route_table_association" "this" {
  for_each = { for ea in local.endpoint_associations : ea.key => ea }
  vpc_endpoint_id =  lookup(var.vpc_endpoint_ids, each.value.vpc_endpoint_name, "")
  route_table_id  = aws_route_table.this[each.value.route_table_key].id
}