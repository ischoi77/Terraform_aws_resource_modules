/*
Title: SPCv2 route_table module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/


locals {
  # 각 VPC별로 CSV 파일을 읽어 서브넷 리스트를 생성합니다.
  subnets_by_vpc = {
    for vpc_key, csv_file in var.subnet_csv_files :
    vpc_key => csvdecode(file(csv_file))
  }

  # 각 VPC의 서브넷 리스트를 평면화하여 단일 리스트로 만듭니다.
  # 각 항목에는 vpc_key, name, (선택적으로 cidr) 정보가 포함됩니다.
  processed_subnets = flatten([
    for vpc_key, subnet_list in local.subnets_by_vpc : [
      for s in subnet_list : {
        vpc_key = vpc_key,
        name    = s.name,
        cidr    = lookup(s, "cidr", null)
      }
    ]
  ])

  # 평면화한 리스트를 고유 키를 가지는 map으로 변환합니다.
  # 고유 키는 "<vpc_key>-<subnet_name>" 형식으로 생성합니다.
  route_tables_map = {
    for s in local.processed_subnets :
    "${s.vpc_key}-${s.name}" => s
  }
}

# 각 서브넷에 대해 라우트 테이블을 생성합니다.
resource "aws_route_table" "this" {
  for_each = local.route_tables_map

  vpc_id = var.vpc_ids[each.value.vpc_key]

  tags = merge(
    var.common_tags,
    { "Name" = "${each.value.name}.rt" }
  )
}

# 각 라우트 테이블을 해당 서브넷과 연결합니다.
resource "aws_route_table_association" "this" {
  for_each = local.route_tables_map

  subnet_id      = var.subnet_ids[each.key]
  route_table_id = aws_route_table.this[each.key].id
}
