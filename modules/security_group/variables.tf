variable "aws_region" {
  description = "AWS 리전 (태그에는 사용하지 않습니다)"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

# 각 보안 그룹은 아래 항목을 포함합니다.
# - description: 보안 그룹 설명
# - vpc_id: 소속 VPC ID
# - ingress: 인바운드 규칙 리스트  
#    → 각 규칙은 리스트 형태로 입력 (순서: from_port, to_port, protocol, [cidr_block ...], [옵션: "desc:설명"])
# - egress: 아웃바운드 규칙 리스트 (ingress와 동일한 형식)
# - tags: 개별 태그
variable "security_groups" {
  description = "Security Group 생성 정보를 담은 map(object). 각 key는 보안 그룹 이름"
  type = map(object({
    description = string
    vpc_name      = string
    ingress     = list(list(string))
    egress      = list(list(string))
    tags        = map(string)
  }))
}


variable "vpc_ids" {
  type        = map(string)
}
