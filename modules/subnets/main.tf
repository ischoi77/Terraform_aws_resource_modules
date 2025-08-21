/*
Title: 대규모 서비스 구성을 위한 AWS 리소스 생성 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-03-25
Description: AWS VPC Subnet 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v1.0.0
*/


locals {
  # 각 VPC별 CSV 파일을 읽어 파싱하여 VPC별 서브넷 리스트를 생성
  subnets_by_vpc = {
    for vpc_key, csv_file in var.subnet_csv_files :
    vpc_key => csvdecode(file(csv_file))
  }

  # 각 VPC의 서브넷 리스트를 평면화하여 하나의 리스트로 만듭니다.
  # 각 항목에는 vpc_key, name, cidr, availability_zone 정보가 포함됩니다.
  processed_subnets = flatten([
    for vpc_key, subnet_list in local.subnets_by_vpc : [
      for s in subnet_list : {
        vpc_key           = vpc_key,
        name              = s.name,
        cidr              = s.cidr,
        purpose           = join(".", slice(split(".", s.name), 0, length(split(".", s.name)) - 1))
        availability_zone = element(split(".", s.name),length(split(".", s.name)) - 1)
      }
    ]
  ])

  
  # 평면화한 리스트를 고유 key를 가지는 map으로 변환합니다.
  # 고유 key는 "<vpc_key>-<subnet_name>" 형식으로 생성합니다.
  subnets_map = {
    for s in local.processed_subnets : "${s.vpc_key}-${s.name}" => s
  }

}

resource "aws_subnet" "this" {
  for_each = local.subnets_map

  vpc_id            = var.vpc_ids[each.value.vpc_key]
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone

  tags = merge(
    var.common_tags,
    { "Name" = each.value.name }
  )
  lifecycle {
    ignore_changes = [ tags ]
  }
}