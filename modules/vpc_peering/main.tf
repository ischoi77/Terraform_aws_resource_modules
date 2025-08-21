/*
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-03-24
Description: AWS VPC Peering 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v1.0.0
*/


# VPC Peering Connection 생성
resource "aws_vpc_peering_connection" "this" {
  for_each = var.vpc_peering_config

  # module.vpcs.vpc_ids에서 전달받은 VPC ID 목록을 참조
  vpc_id      = var.vpc_ids[each.value.requester_vpc]
  peer_vpc_id = var.vpc_ids[each.value.accepter_vpc]

  auto_accept   = lookup(each.value, "auto_accept", false)
  peer_region   = lookup(each.value, "peer_region", null)
  peer_owner_id = lookup(each.value, "peer_owner_id", null)

  tags = merge(var.common_tags, lookup(each.value, "tags", {}))
}

# 선택 사항: VPC Peering Connection Options 생성 (예, DNS 해상도 허용 등)
resource "aws_vpc_peering_connection_options" "this" {
  for_each = {
    for k, v in var.vpc_peering_config : k => v
    if contains(keys(v), "accepter_options") || contains(keys(v), "requester_options")
  }

  vpc_peering_connection_id = aws_vpc_peering_connection.this[each.key].id

  dynamic "accepter" {
    for_each = each.value.accepter_options != null ? [each.value.accepter_options] : []
    content {
      allow_remote_vpc_dns_resolution = lookup(accepter.value, "allow_remote_vpc_dns_resolution", false)
      # 필요 시 추가 accepter 옵션 입력 가능
    }
  }

  dynamic "requester" {
    for_each = each.value.requester_options != null ? [each.value.requester_options] : []
    content {
      allow_remote_vpc_dns_resolution = lookup(requester.value, "allow_remote_vpc_dns_resolution", false)
      # 필요 시 추가 requester 옵션 입력 가능
    }
  }
}