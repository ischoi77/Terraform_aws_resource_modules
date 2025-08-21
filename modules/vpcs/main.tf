/*
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-03-24
Description: AWS VPC 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v3.0.0
*/


resource "aws_vpc" "this" {
  for_each = var.vpcs

  cidr_block = each.value.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = merge(
    var.common_tags,
    each.value.tags
  )
}

locals {
  additional_cidr_entries = flatten([
    for vpc_key, vpc in var.vpcs : [
      for cidr in vpc.additional_cidrs : {
        vpc_key = vpc_key
        cidr    = cidr
      }
    ]
  ])
  vpcs_with_dhcp = { for key, vpc in var.vpcs : key => vpc if vpc.dhcp_options != null }
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = { for entry in local.additional_cidr_entries : "${entry.vpc_key}-${replace(entry.cidr, "/", "-")}" => entry }

  vpc_id     = aws_vpc.this[each.value.vpc_key].id
  cidr_block = each.value.cidr
}


resource "aws_vpc_dhcp_options" "this" {
  for_each = local.vpcs_with_dhcp

  domain_name          = each.value.dhcp_options.domain_name
  domain_name_servers  = each.value.dhcp_options.domain_name_servers
  ntp_servers          = each.value.dhcp_options.ntp_servers
  netbios_name_servers = each.value.dhcp_options.netbios_name_servers
  netbios_node_type    = each.value.dhcp_options.netbios_node_type

}


resource "aws_vpc_dhcp_options_association" "this" {
  for_each = local.vpcs_with_dhcp

  vpc_id           = aws_vpc.this[each.key].id
  dhcp_options_id  = aws_vpc_dhcp_options.this[each.key].id
}

# IGW 생성 (각 VPC별 igw_create 값에 따라 생성)
resource "aws_internet_gateway" "igw" {
  for_each = { for key, vpc in var.vpcs : key => vpc if vpc.igw_create }

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(
    var.common_tags,
    { "Name" = replace(each.key, "vpc", "igw") }
  )
}