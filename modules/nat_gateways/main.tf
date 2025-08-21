/*
Title: AWS NAT-Gateway module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/


locals {
  # CSV 파일을 읽어 리스트 오브젝트로 변환 (CSV 파일은 반드시 헤더 row가 있어야 함)
  nat_gateways_raw = csvdecode(file(var.nat_gateway_csv_file))

  # CSV 파일의 각 행을 nat_gateway_name을 key로 갖는 map으로 재구성하고,
  # public 필드는 소문자 비교를 통해 bool 값으로 변환하며 allocation_id는 trim 처리함.
  nat_gateways = {
    for row in local.nat_gateways_raw : row.nat_gateway_name => {
      nat_gateway_name = row.nat_gateway_name
      subnet           = row.subnet
      public           = lower(trimspace(row.public)) == "true"
      allocation_id = trimspace(row.allocation_id)
      tag_entries = [
        { key = trimspace(row.key1), value = trimspace(row.value1) },
        { key = trimspace(row.key2), value = trimspace(row.value2) },
        { key = trimspace(row.key3), value = trimspace(row.value3) },
        { key = trimspace(row.key4), value = trimspace(row.value4) },
      ]
    }
  }

  # public NAT Gateway 중 allocation_id 값이 비어있는 항목에 대해 EIP를 생성해야 함.
  nat_gateways_eip_required = {
    for key, ng in local.nat_gateways : key => ng
    if ng.public && (ng.allocation_id == "" || ng.allocation_id == null)
  }
}

# 필요한 경우, public NAT Gateway에 대해 Elastic IP를 생성합니다.
resource "aws_eip" "this" {
  for_each = local.nat_gateways_eip_required

  #vpc = true
  
  tags = merge(
    var.common_tags,
    { Name = "${each.key}-eip" }
  )
}

# 각 NAT Gateway를 생성합니다.
resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateways

  subnet_id = var.subnet_ids[each.value.subnet]



  # public NAT Gateway의 경우 allocation_id가 필요합니다.
  # CSV에 값이 있으면 해당 allocation_id를 사용하고,
  # 값이 비어있으면 생성한 EIP의 allocation_id를 사용합니다.
  allocation_id = each.value.public ? (
    each.value.allocation_id != "" ? each.value.allocation_id : data.aws_eip.natgw_eip_lookup[each.key].id
  ) : null

  tags = merge(
    var.common_tags,
    # CSV의 key/value 쌍을 태그로 변환 (null 또는 빈 문자열은 자동 제외)
    { for t in each.value.tag_entries : t.key => t.value
      if t.key   != null && t.key   != "" &&
         t.value != null && t.value != ""
    },
    { Name = each.key }
  )
  # NAT Gateway 생성 시, EIP가 필요한 경우 해당 EIP 리소스 생성이 완료된 후에 진행하도록 의존성을 설정합니다.
  depends_on = [aws_eip.this]

  # 최초 생성시 만 필요한 allocation_id 생성 로직에 대해 변경에 대한 내용을 무시하도록 설정
  lifecycle {
    ignore_changes = [ allocation_id ]
  }
}

data "aws_eip" "natgw_eip_lookup" {
  for_each = local.nat_gateways_eip_required

  filter {
    name   = "tag:Name"
    values = ["${each.key}-eip"]
  }

  # EIP 리소스가 생성된 이후에 조회하도록 명시
  depends_on = [aws_eip.this]
}