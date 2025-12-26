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

  # KeyPair 생성 대상만 필터
  keypairs = {
    for k, v in var.instances :
    k => v
    if try(v.create_key_pair, false) == true
  }

  # Instance Profile 생성 대상만 필터
  profiles = {
    for k, v in var.instances :
    k => v
    if try(v.create_instance_profile, false) == true
  }

  # EIP 생성 대상만 필터
  eips = {
    for k, v in var.instances :
    k => v
    if try(v.allocate_eip, false) == true
  }

  # # Extra EBS volumes flatten
  # extra_ebs = flatten([
  #   for ik, iv in var.instances : [
  #     for idx, vol in try(iv.extra_ebs_volumes, []) : {
  #       inst_key = ik
  #       idx      = idx
  #       vol      = vol
  #     }
  #   ]
  # ])

  # extra_ebs_map = {
  #   for x in local.extra_ebs :
  #   "${x.inst_key}-${x.idx}" => x
  # }

  # ENI flatten
  # enis = flatten([
  #   for ik, iv in var.instances : [
  #     for idx, eni in try(iv.create_enis, []) : {
  #       inst_key = ik
  #       idx      = idx
  #       eni      = eni
  #     }
  #   ]
  # ])

  # enis_map = {
  #   for x in local.enis :
  #   "${x.inst_key}-${x.idx}" => x
  # }

# ===== 외부모듈에서 입력값 subnet_ids, security_group_ids 변환 =====
  resolved_subnet_ids = {
    for inst_name, inst in var.instances :
    inst_name => (
      try(inst.subnet_name, null) == null
      ? null
      : lookup(var.subnet_ids, inst.subnet_name, null)
    )
  }

  resolved_vpc_security_group_ids = {
    for inst_name, inst in var.instances :
    inst_name => (
      try(inst.vpc_security_group_names, null) == null
      ? null
      : compact([
          for sg_key in inst.vpc_security_group_names :
          lookup(var.security_group_ids, sg_key, null)
        ])
    )
  }
}

# # ===== plan 단계에서 SG 키 오타/누락 잡기(권장) =====
# check "security_group_key_validation" {
#   assert = alltrue(flatten([
#     for _, inst in var.instances : [
#       for sg in try(inst.vpc_security_group_names, []) :
#       contains(keys(var.security_group_ids), sg)
#     ]
#   ]))
#   error_message = "instances.vpc_security_group_names 중 <vpc_name>_<sg_name> 형식의 SG key가 security_group_ids(output)에 존재하지 않습니다."
# }

# =========================
# (옵션) Key Pair 생성
# =========================
resource "aws_key_pair" "this" {
  for_each = local.keypairs

  key_name   = try(each.value.key_name, each.key)
  public_key = each.value.public_key

  tags = merge(local.instance_tags[each.key], {
    "ManagedBy" = "Terraform"
  })
}

# =========================
# (옵션) IAM Instance Profile 생성
# =========================
resource "aws_iam_instance_profile" "this" {
  for_each = local.profiles

  name = coalesce(
    try(each.value.instance_profile_name, null),
    "${each.key}-profile"
  )

  role = each.value.instance_profile_role_name
  path = try(each.value.instance_profile_path, null)

  tags = merge(
    local.instance_tags[each.key],
    try(each.value.instance_profile_tags, {})
  )
}

# =========================
# (옵션) 별도 ENI 생성
# =========================
# resource "aws_network_interface" "this" {
#   for_each = local.enis_map

#   subnet_id         = each.value.eni.subnet_id
#   private_ips       = try(each.value.eni.private_ips, null)
#   security_groups   = try(each.value.eni.security_groups, null)
#   source_dest_check = try(each.value.eni.source_dest_check, null)
#   description       = try(each.value.eni.description, null)

#   tags = merge(
#     local.instance_tags[each.value.inst_key],
#     try(each.value.eni.tags, {}),
#     { "ENIIndex" = tostring(each.value.idx) }
#   )
# }

# resource "aws_network_interface_attachment" "this" {
#   for_each = {
#     for k, v in local.enis_map :
#     k => v
#     if try(v.eni.attachment, null) != null
#   }

#   instance_id          = aws_instance.this[each.value.inst_key].id
#   network_interface_id = aws_network_interface.this[each.key].id
#   device_index         = each.value.eni.attachment.device_index
#   #network_card_index   = try(each.value.eni.attachment.network_card_index, null)
# }

# =========================
# EC2 Instance
# =========================
resource "aws_instance" "this" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  availability_zone           = try(each.value.availability_zone, null)

  # subnet 이름키 목록 -> subnet-id 목록 =====
  subnet_id                   = try(local.resolved_subnet_ids[each.key], null)
  associate_public_ip_address = try(each.value.associate_public_ip_address, null)
  private_ip                  = try(each.value.private_ip, null)
  ipv6_address_count          = try(each.value.ipv6_address_count, null)
  ipv6_addresses              = try(each.value.ipv6_addresses, null)

  # key_name: 생성한 keypair가 있으면 그것을 우선 사용, 아니면 입력값
  key_name = (
    try(each.value.create_key_pair, false) == true
    ? aws_key_pair.this[each.key].key_name
    : try(each.value.key_name, null)
  )

  iam_instance_profile = (
    try(each.value.create_instance_profile, false) == true
    ? aws_iam_instance_profile.this[each.key].name
    : try(each.value.iam_instance_profile, null)
  )

  user_data                   = try(each.value.user_data, null)
  user_data_base64            = try(each.value.user_data_base64, null)
  user_data_replace_on_change = try(each.value.user_data_replace_on_change, null)

  monitoring              = try(each.value.monitoring, null)
  get_password_data       = try(each.value.get_password_data, null)
  disable_api_stop        = try(each.value.disable_api_stop, null)
  disable_api_termination = try(each.value.disable_api_termination, null)
  ebs_optimized           = try(each.value.ebs_optimized, null)
  hibernation             = try(each.value.hibernation, null)
  host_id                 = try(each.value.host_id, null)
  host_resource_group_arn = try(each.value.host_resource_group_arn, null)
  placement_group         = try(each.value.placement_group, null)
  tenancy                 = try(each.value.tenancy, null)
  source_dest_check       = try(each.value.source_dest_check, null)
  #shutdown_behavior       = try(each.value.shutdown_behavior, null)
  instance_initiated_shutdown_behavior = try(each.value.instance_initiated_shutdown_behavior, null)

  # SG 이름키 목록 -> sg-id 목록 =====
  vpc_security_group_ids = try(local.resolved_vpc_security_group_ids[each.key], null)

  # EC2-Classic 용(보통 미사용)
  security_groups = try(each.value.security_groups, null)

  volume_tags = try(each.value.volume_tags, null)

  dynamic "metadata_options" {
    for_each = try(each.value.metadata_options, null) == null ? [] : [each.value.metadata_options]
    content {
      http_endpoint               = try(metadata_options.value.http_endpoint, null)
      http_protocol_ipv6          = try(metadata_options.value.http_protocol_ipv6, null)
      http_put_response_hop_limit = try(metadata_options.value.http_put_response_hop_limit, null)
      http_tokens                 = try(metadata_options.value.http_tokens, null)
      instance_metadata_tags      = try(metadata_options.value.instance_metadata_tags, null)
    }
  }

  dynamic "enclave_options" {
    for_each = try(each.value.enclave_options, null) == null ? [] : [each.value.enclave_options]
    content {
      enabled = enclave_options.value.enabled
    }
  }

  dynamic "credit_specification" {
    for_each = try(each.value.credit_specification, null) == null ? [] : [each.value.credit_specification]
    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "cpu_options" {
    for_each = try(each.value.cpu_options, null) == null ? [] : [each.value.cpu_options]
    content {
      core_count       = try(cpu_options.value.core_count, null)
      threads_per_core = try(cpu_options.value.threads_per_core, null)
      amd_sev_snp      = try(cpu_options.value.amd_sev_snp, null)
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = try(each.value.capacity_reservation_specification, null) == null ? [] : [each.value.capacity_reservation_specification]
    content {
      capacity_reservation_preference = try(capacity_reservation_specification.value.capacity_reservation_preference, null)
      dynamic "capacity_reservation_target" {
        for_each = try(capacity_reservation_specification.value.capacity_reservation_target, null) == null ? [] : [capacity_reservation_specification.value.capacity_reservation_target]
        content {
          capacity_reservation_id                 = try(capacity_reservation_target.value.capacity_reservation_id, null)
          capacity_reservation_resource_group_arn = try(capacity_reservation_target.value.capacity_reservation_resource_group_arn, null)
        }
      }
    }
  }

  dynamic "maintenance_options" {
    for_each = try(each.value.maintenance_options, null) == null ? [] : [each.value.maintenance_options]
    content {
      auto_recovery = try(maintenance_options.value.auto_recovery, null)
    }
  }

  dynamic "private_dns_name_options" {
    for_each = try(each.value.private_dns_name_options, null) == null ? [] : [each.value.private_dns_name_options]
    content {
      enable_resource_name_dns_a_record    = try(private_dns_name_options.value.enable_resource_name_dns_a_record, null)
      enable_resource_name_dns_aaaa_record = try(private_dns_name_options.value.enable_resource_name_dns_aaaa_record, null)
      hostname_type                        = try(private_dns_name_options.value.hostname_type, null)
    }
  }

  dynamic "instance_market_options" {
    for_each = try(each.value.instance_market_options, null) == null ? [] : [each.value.instance_market_options]
    content {
      market_type = instance_market_options.value.market_type
      dynamic "spot_options" {
        for_each = try(instance_market_options.value.spot_options, null) == null ? [] : [instance_market_options.value.spot_options]
        content {
          max_price                      = try(spot_options.value.max_price, null)
          spot_instance_type             = try(spot_options.value.spot_instance_type, null)
          instance_interruption_behavior = try(spot_options.value.instance_interruption_behavior, null)
          valid_until                    = try(spot_options.value.valid_until, null)
          #valid_from                     = try(spot_options.value.valid_from, null)
        }
      }
    }
  }

  dynamic "launch_template" {
    for_each = try(each.value.launch_template, null) == null ? [] : [each.value.launch_template]
    content {
      id      = try(launch_template.value.id, null)
      name    = try(launch_template.value.name, null)
      version = try(launch_template.value.version, null)
    }
  }

  dynamic "network_interface" {
    for_each = try(each.value.network_interfaces, [])
    content {
      device_index          = network_interface.value.device_index
      network_interface_id  = try(network_interface.value.network_interface_id, null)
      delete_on_termination = try(network_interface.value.delete_on_termination, null)
      network_card_index    = try(network_interface.value.network_card_index, null)
    }
  }

  dynamic "root_block_device" {
    for_each = try(each.value.root_block_device, null) == null ? [] : [each.value.root_block_device]
    content {
      delete_on_termination = try(root_block_device.value.delete_on_termination, null)
      encrypted             = try(root_block_device.value.encrypted, null)
      iops                  = try(root_block_device.value.iops, null)
      kms_key_id            = try(root_block_device.value.kms_key_id, null)
      throughput            = try(root_block_device.value.throughput, null)
      volume_size           = try(root_block_device.value.volume_size, null)
      volume_type           = try(root_block_device.value.volume_type, null)
      tags                  = try(root_block_device.value.tags, null)
    }
  }

  dynamic "ebs_block_device" {
    for_each = try(each.value.ebs_block_devices, [])
    content {
      device_name           = ebs_block_device.value.device_name
      delete_on_termination = try(ebs_block_device.value.delete_on_termination, null)
      encrypted             = try(ebs_block_device.value.encrypted, null)
      iops                  = try(ebs_block_device.value.iops, null)
      kms_key_id            = try(ebs_block_device.value.kms_key_id, null)
      snapshot_id           = try(ebs_block_device.value.snapshot_id, null)
      throughput            = try(ebs_block_device.value.throughput, null)
      volume_size           = try(ebs_block_device.value.volume_size, null)
      volume_type           = try(ebs_block_device.value.volume_type, null)
      tags                  = try(ebs_block_device.value.tags, null)
    }
  }

  dynamic "ephemeral_block_device" {
    for_each = try(each.value.ephemeral_block_devices, [])
    content {
      device_name  = ephemeral_block_device.value.device_name
      virtual_name = ephemeral_block_device.value.virtual_name
      no_device    = try(ephemeral_block_device.value.no_device, null)
    }
  }

  tags = local.instance_tags[each.key]

  # depends_on = [
  #   aws_network_interface.this
  # ]
}

# =========================
# (옵션) Elastic IP + Association
# =========================
resource "aws_eip" "this" {
  for_each = local.eips

  domain = try(each.value.eip_domain, "vpc")

  tags = merge(
    local.instance_tags[each.key],
    try(each.value.eip_tags, {})
  )
}

resource "aws_eip_association" "this" {
  for_each = local.eips

  instance_id   = aws_instance.this[each.key].id
  allocation_id = aws_eip.this[each.key].id
}

# =========================
# (옵션) Extra EBS Volume + Attachment
# =========================
# resource "aws_ebs_volume" "extra" {
#   for_each = local.extra_ebs_map

#   availability_zone = coalesce(
#     try(each.value.vol.availability_zone, null),
#     aws_instance.this[each.value.inst_key].availability_zone
#   )

#   size                 = try(each.value.vol.size, null)
#   type                 = try(each.value.vol.type, null)
#   iops                 = try(each.value.vol.iops, null)
#   throughput           = try(each.value.vol.throughput, null)
#   encrypted            = try(each.value.vol.encrypted, null)
#   kms_key_id           = try(each.value.vol.kms_key_id, null)
#   snapshot_id          = try(each.value.vol.snapshot_id, null)
#   multi_attach_enabled = try(each.value.vol.multi_attach_enabled, null)

#   tags = merge(
#     local.instance_tags[each.value.inst_key],
#     try(each.value.vol.tags, {}),
#     { "ExtraEBSIndex" = tostring(each.value.idx) }
#   )
# }

# resource "aws_volume_attachment" "extra" {
#   for_each = local.extra_ebs_map

#   device_name = each.value.vol.device_name
#   volume_id   = aws_ebs_volume.extra[each.key].id
#   instance_id = aws_instance.this[each.value.inst_key].id

#   force_detach                 = try(each.value.vol.force_detach, null)
#   skip_destroy                 = try(each.value.vol.skip_destroy, null)
#   stop_instance_before_detaching = try(each.value.vol.stop_instance_before_detaching, null)
# }
