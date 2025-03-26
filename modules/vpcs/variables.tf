variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "vpcs" {
  description = "VPC 생성 정보를 담은 map(object). 각 key는 VPC 이름"
  type = map(object({
    cidr_block       = string
    additional_cidrs = list(string)  # 추가 CIDR 블록 목록 (없으면 빈 리스트)
    igw_create = optional(bool, false) # 기본적으로 IGW 미생성
    tags             = map(string)
  }))
}