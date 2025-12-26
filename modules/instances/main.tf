provider "aws" {
  region = var.aws_region
}

locals {
  instance_tags = {
    for k, v in var.instances :
    k => merge(
      var.common_tags,
      try(v.tags, {}),
      { Name = k }
    )
  }

  resolved_subnet_ids = {
    for inst_name, inst in var.instances :
    inst_name => lookup(var.subnet_ids, inst.subnet_name, null)
  }

  resolved_vpc_security_group_ids = {
    for inst_name, inst in var.instances :
    inst_name => compact([
      for sg_key in inst.vpc_security_group_names :
      lookup(var.security_group_ids, sg_key, null)
    ])
  }

  eips = {
    for k, v in var.instances :
    k => v
    if try(v.allocate_eip, false) == true
  }
}

# ----- EC2 Instance -----
resource "aws_instance" "this" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  subnet_id              = local.resolved_subnet_ids[each.key]
  vpc_security_group_ids = local.resolved_vpc_security_group_ids[each.key]

  associate_public_ip_address = try(each.value.associate_public_ip_address, null)
  private_ip                  = try(each.value.private_ip, null)

  key_name             = try(each.value.key_name, null)
  iam_instance_profile = try(each.value.iam_instance_profile, null)

  user_data = try(each.value.user_data, null)

  tags = local.instance_tags[each.key]
}

# ----- (옵션) Elastic IP -----
resource "aws_eip" "this" {
  for_each = local.eips

  domain = try(each.value.eip_domain, "vpc")

  tags = merge(local.instance_tags[each.key], {
    "EIP" = "true"
  })
}

resource "aws_eip_association" "this" {
  for_each = local.eips

  instance_id   = aws_instance.this[each.key].id
  allocation_id = aws_eip.this[each.key].id
}
