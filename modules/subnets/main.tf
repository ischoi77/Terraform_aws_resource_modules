
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

  subnets_by_tag_group = {
    App = {
      for k, s in local.subnets_map :
      k => s if can(regex("\\.app\\.", s.name))
    }
    Ops = {
      for k, s in local.subnets_map :
      k => s if (
        can(regex("\\.ops\\.", s.name)) || can(regex("\\.infra\\.", s.name))
      )
    }
  }
  subnet_tag_sets = {
    app = [
      {
        key   = var.subent_tags.app.key1
        value = var.subent_tags.app.value1
      },
      {
        key   = var.subent_tags.app.key2
        value = var.subent_tags.app.value2
      },
      {
        key   = var.subent_tags.app.key3
        value = var.subent_tags.app.value3
      },
      {
        key   = var.subent_tags.app.key4
        value = var.subent_tags.app.value4
      },
    ]
    ops = [
      {
        key   = var.subent_tags.ops.key1
        value = var.subent_tags.ops.value1
      },
      {
        key   = var.subent_tags.ops.key2
        value = var.subent_tags.ops.value2
      },
      {
        key   = var.subent_tags.ops.key3
        value = var.subent_tags.ops.value3
      },
      {
        key   = var.subent_tags.ops.key4
        value = var.subent_tags.ops.value4
      },
    ]
  }
  app_tag_pairs = flatten([
    for subnet_key, subnet in local.subnets_by_tag_group.App : [
      for idx, tag in local.subnet_tag_sets.app : {
        key         = "${subnet_key}-${idx}"
        subnet_name = subnet.name
        tag_key     = tag.key
        tag_value   = tag.value
      }
    ]
  ])
  ops_tag_pairs = flatten([
    for subnet_key, subnet in local.subnets_by_tag_group.Ops : [
      for idx, tag in local.subnet_tag_sets.ops : {
        key         = "${subnet_key}-${idx}"
        subnet_name = subnet.name
        tag_key     = tag.key
        tag_value   = tag.value
      }
    ]
  ])

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


resource "aws_ec2_tag" "subnet_all" {
  for_each = local.subnets_map
  resource_id = aws_subnet.this[each.key].id
  key = "immutable_metadata"
  value = jsonencode({"purpose" = "${each.value.purpose}"})
}


resource "aws_ec2_tag" "subnet_app_group" {
  for_each = {
    for tag in local.app_tag_pairs : tag.key => tag
  }

  resource_id = aws_subnet.this[each.value.subnet_name].id
  key         = each.value.tag_key
  value       = each.value.tag_value
}

resource "aws_ec2_tag" "subnet_ops_group" {
  for_each = {
    for tag in local.ops_tag_pairs : tag.key => tag
  }

  resource_id = aws_subnet.this[each.value.subnet_name].id
  key         = each.value.tag_key
  value       = each.value.tag_value
}



# resource "aws_ec2_tag" "app_class0" {
#   for_each = local.subnets_by_tag_group.App
#   resource_id = aws_subnet.this[each.key].id
#   key = "class0"
#   value = "Service"
# }
# resource "aws_ec2_tag" "app_class1" {
#   for_each = local.subnets_by_tag_group.App
#   resource_id = aws_subnet.this[each.key].id
#   key = "class1"
#   value = "Backend"
# }
# resource "aws_ec2_tag" "app_gbl_class0" {
#   for_each = local.subnets_by_tag_group.App
#   resource_id = aws_subnet.this[each.key].id
#   key = "GBL_CLASS_0"
#   value = "SERVICE"
# }
# resource "aws_ec2_tag" "app_gbl_class1" {
#   for_each = local.subnets_by_tag_group.App
#   resource_id = aws_subnet.this[each.key].id
#   key = "GBL_CLASS_1"
#   value = "BACKEND"
# }
# resource "aws_ec2_tag" "ops_class0" {
#   for_each = local.subnets_by_tag_group.Ops
#   resource_id = aws_subnet.this[each.key].id
#   key = "class0"
#   value = "Operation"
# }
# resource "aws_ec2_tag" "ops_class1" {
#   for_each = local.subnets_by_tag_group.Ops
#   resource_id = aws_subnet.this[each.key].id
#   key = "class1"
#   value = "Infra"
# }
# resource "aws_ec2_tag" "ops_gbl_class0" {
#   for_each = local.subnets_by_tag_group.Ops
#   resource_id = aws_subnet.this[each.key].id
#   key = "GBL_CLASS_0"
#   value = "OPERATION"
# }
# resource "aws_ec2_tag" "ops_gbl_class1" {
#   for_each = local.subnets_by_tag_group.Ops
#   resource_id = aws_subnet.this[each.key].id
#   key = "GBL_CLASS_1"
#   value = "INFRA"
# }
