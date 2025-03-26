/*
Title: SPCv2 route_table module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/

locals {
  # 각 route table별로 ip_lists 파일을 읽어 destination CIDR 블록을 가져오고,
  # 해당 route table의 gateway 타입에 따라 igw_ids 또는 ngw_ids 리스트에서 인덱스 기반으로 gateway_id를 할당합니다.
  parsed_routes = {
    for rt_key, rt in var.route_tables : rt_key => [
      for index, line in split("\n", trim(file("${path.root}/ip_lists/${rt.route_key}.list"))) :
      {
        destination_cidr_block = trim(line)
        gateway_id = (
          rt.gateway == "igw" ? element(var.igw_ids, index) :
          rt.gateway == "ngw" ? element(var.ngw_ids, index) :
          ""
        )
      }
    ]
  }
}

# Route Table 생성 (각 route table은 지정된 VPC 내에 생성됨)
resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = var.vpc_id

  tags = merge(
    var.common_tags,
    each.value.tags,
    { Name = each.value.name }
  )
}

# 각 ip_lists 파일의 각 라인에 대해 aws_route 리소스를 생성
resource "aws_route" "this" {
  for_each = {
    for rt_key, routes in local.parsed_routes :
    for idx, route in routes :
      "${rt_key}-${idx}" => merge(route, { route_table_id = aws_route_table.this[rt_key].id })
  }

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gateway_id
}

# 각 route table에 지정된 서브넷과 연결하는 aws_route_table_association 리소스 생성
resource "aws_route_table_association" "this" {
  for_each = {
    for rt_key, rt in var.route_tables :
    for idx, subnet in rt.subnets :
      "${rt_key}-${idx}" => {
        route_table_id = aws_route_table.this[rt_key].id
        subnet_id      = subnet
      }
  }

  route_table_id = each.value.route_table_id
  subnet_id      = each.value.subnet_id
}
