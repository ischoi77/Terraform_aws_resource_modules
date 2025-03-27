/*
Title: SPCv2 VPC module
Author: Inseok-Choi
contect: is25.choi@partner.samsung.com, ischoi.scloud@gmail.com

*/


resource "aws_vpc" "this" {
  for_each = var.vpcs

  cidr_block = each.value.cidr_block

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
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = { for idx, entry in local.additional_cidr_entries : "${entry.vpc_key}-${idx}" => entry }

  vpc_id     = aws_vpc.this[each.value.vpc_key].id
  cidr_block = each.value.cidr
}


resource "aws_vpc_dhcp_options" "this" {
  for_each = var.vpcs
  # domain_name_servers = ["8.8.8.8"]
  domain_name_servers = each.value.dhcp_domain_name_servers
  domain_name         = each.value.dhcp_domain_name
}


# IGW 생성 (각 VPC별 igw_create 값에 따라 생성)
resource "aws_internet_gateway" "igw" {
  for_each = { for key, vpc in var.vpcs : key => vpc if vpc.igw_create }

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(
    var.common_tags,
    { "Name" = "${each.key}-igw" }
  )
}