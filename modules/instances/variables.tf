variable "aws_region" {
  description = "리전 정보"
  type        = string
}

variable "common_tags" {
  description = "공용 tag 값 (리소스별 tags 와 병합)"
  type        = map(string)
  default     = {}
}

variable "security_group_ids" {
  description = "security_groups 모듈 output (key=<vpc_name>_<sg_name>, value=sg-xxxx)"
  type        = map(string)
  default     = {}
}

variable "instances" {
  description = "키=리소스명(Name 태그로도 사용). 값=EC2 설정"
  type = map(object({
    # ===== 필수/기본 =====
    ami           = string
    instance_type = string

    # ===== 선택(주요) =====
    availability_zone           = optional(string)
    subnet_id                   = optional(string)
    associate_public_ip_address = optional(bool)
    private_ip                  = optional(string)
    ipv6_address_count          = optional(number)
    ipv6_addresses              = optional(list(string))

    key_name                    = optional(string) # 기존 키 사용
    create_key_pair             = optional(bool)   # true면 aws_key_pair 생성
    public_key                  = optional(string) # create_key_pair 시 필요

    iam_instance_profile        = optional(string) # 기존 instance profile 사용
    create_instance_profile     = optional(bool)   # true면 profile 생성
    instance_profile_name       = optional(string) # 미지정 시 each.key 기반
    instance_profile_path       = optional(string)
    instance_profile_role_name  = optional(string) # create_instance_profile 시 필요
    instance_profile_tags       = optional(map(string))

    user_data                   = optional(string)
    user_data_base64            = optional(string)
    user_data_replace_on_change = optional(bool)

    monitoring                  = optional(bool)
    get_password_data           = optional(bool)
    disable_api_stop            = optional(bool)
    disable_api_termination     = optional(bool)
    ebs_optimized               = optional(bool)
    hibernation                 = optional(bool)
    host_id                     = optional(string)
    host_resource_group_arn     = optional(string)
    placement_group             = optional(string)
    tenancy                     = optional(string) # default/dedicated/host
    source_dest_check           = optional(bool)
    shutdown_behavior           = optional(string) # stop/terminate
    instance_initiated_shutdown_behavior = optional(string) # stop/terminate

    # ===== 변경: SG 이름(<vpc>_<sg>)으로 받기 =====
    vpc_security_group_names = optional(list(string))
    security_groups          = optional(list(string)) # EC2-Classic 용(일반 VPC는 위 names 사용 권장)

    # ===== 태그 =====
    tags        = optional(map(string))
    volume_tags = optional(map(string))

    # ===== 고급 옵션/블록들 =====
    metadata_options = optional(object({
      http_endpoint               = optional(string)
      http_protocol_ipv6          = optional(string)
      http_put_response_hop_limit = optional(number)
      http_tokens                 = optional(string)
      instance_metadata_tags      = optional(string)
    }))

    enclave_options = optional(object({
      enabled = bool
    }))

    credit_specification = optional(object({
      cpu_credits = string
    }))

    cpu_options = optional(object({
      core_count       = optional(number)
      threads_per_core = optional(number)
      amd_sev_snp      = optional(string)
    }))

    capacity_reservation_specification = optional(object({
      capacity_reservation_preference = optional(string)
      capacity_reservation_target = optional(object({
        capacity_reservation_id                 = optional(string)
        capacity_reservation_resource_group_arn = optional(string)
      }))
    }))

    maintenance_options = optional(object({
      auto_recovery = optional(string)
    }))

    private_dns_name_options = optional(object({
      enable_resource_name_dns_a_record    = optional(bool)
      enable_resource_name_dns_aaaa_record = optional(bool)
      hostname_type                        = optional(string)
    }))

    instance_market_options = optional(object({
      market_type = string # spot
      spot_options = optional(object({
        max_price                      = optional(string)
        spot_instance_type             = optional(string)
        instance_interruption_behavior = optional(string)
        valid_until                    = optional(string)
        valid_from                     = optional(string)
      }))
    }))

    launch_template = optional(object({
      id      = optional(string)
      name    = optional(string)
      version = optional(string)
    }))

    # aws_instance inline network_interface 블록
    network_interfaces = optional(list(object({
      device_index          = number
      network_interface_id  = optional(string)
      delete_on_termination = optional(bool)
      network_card_index    = optional(number)
    })))

    # root/ebs/ephemeral 블록
    root_block_device = optional(object({
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string)
      tags                  = optional(map(string))
    }))

    ebs_block_devices = optional(list(object({
      device_name           = string
      delete_on_termination = optional(bool)
      encrypted             = optional(bool)
      iops                  = optional(number)
      kms_key_id            = optional(string)
      snapshot_id           = optional(string)
      throughput            = optional(number)
      volume_size           = optional(number)
      volume_type           = optional(string)
      tags                  = optional(map(string))
    })))

    ephemeral_block_devices = optional(list(object({
      device_name  = string
      virtual_name = string
      no_device    = optional(bool)
    })))

    # ===== 추가 리소스(옵션) =====
    # 1) Elastic IP
    allocate_eip = optional(bool)
    eip_domain   = optional(string) # vpc
    eip_tags     = optional(map(string))

    # 2) Extra EBS volumes (aws_ebs_volume + aws_volume_attachment)
    extra_ebs_volumes = optional(list(object({
      device_name                   = string
      availability_zone             = optional(string)
      size                          = optional(number)
      type                          = optional(string)
      iops                          = optional(number)
      throughput                    = optional(number)
      encrypted                     = optional(bool)
      kms_key_id                    = optional(string)
      snapshot_id                   = optional(string)
      multi_attach_enabled          = optional(bool)
      tags                          = optional(map(string))
      delete_on_termination          = optional(bool)
      force_detach                  = optional(bool)
      skip_destroy                  = optional(bool)
      stop_instance_before_detaching = optional(bool)
    })))

    # 3) ENI 별도 생성 (aws_network_interface + attachment)
    create_enis = optional(list(object({
      subnet_id         = string
      private_ips       = optional(list(string))
      security_groups   = optional(list(string))
      source_dest_check = optional(bool)
      description       = optional(string)
      tags              = optional(map(string))
      attachment = optional(object({
        device_index          = number
        network_card_index    = optional(number)
        delete_on_termination = optional(bool)
      }))
    })))
  }))
}
