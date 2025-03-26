variable "aws_region" {
  description = "AWS 리전 정보"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통적으로 적용할 태그. 각 리소스별 tags와 병합됨"
  type        = map(string)
  default     = {}
}

variable "vpc_ids" {
  description = "module.vpcs.vpc_ids에서 전달받은, VPC 이름을 키로 하는 VPC ID 목록"
  type        = map(string)
}

variable "vpc_peering_config" {
  description = "VPC 피어링 구성 정보. 각 항목은 peering 연결에 필요한 정보를 포함합니다."
  type = map(object({
    requester_vpc = string  # 피어링 요청 VPC의 이름 (vpc_ids의 키)
    accepter_vpc  = string  # 피어링 대상 VPC의 이름 (vpc_ids의 키)
    auto_accept   = optional(bool, false)
    peer_region   = optional(string)
    peer_owner_id = optional(string)
    tags          = optional(map(string), {})

    # 선택 사항: VPC Peering Connection Options
    requester_options = optional(object({
      allow_remote_vpc_dns_resolution = optional(bool, false)
      # 필요 시 추가 requester 옵션을 정의
    }), null)
    accepter_options = optional(object({
      allow_remote_vpc_dns_resolution = optional(bool, false)
      # 필요 시 추가 accepter 옵션을 정의
    }), null)
  }))
}
