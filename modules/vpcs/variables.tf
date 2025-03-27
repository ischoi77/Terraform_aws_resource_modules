variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "vpcs" {
  description = "VPC 생성 정보를 담은 map(object)"
  type = map(object({
    cidr_block       = string
    dhcp_domain_name_servers = list(string)
    dhcp_domain_name         = string
    additional_cidrs = list(string)
    igw_create = optional(bool, false) # 기본적으로 IGW 미생성
    tags             = map(string)
  }))
}
