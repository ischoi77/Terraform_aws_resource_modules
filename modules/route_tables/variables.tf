variable "vpc_id" {
  description = "Route table을 생성할 VPC ID"
  type        = string
}

variable "route_tables" {
  description = "각 route table에 대한 구성 정보"
  type = map(object({
    name      = string         // route table 이름
    route_key = string         // ip_lists/<route_key>.list 파일 접두어 (파일은 destination CIDR만 포함)
    gateway   = string         // 사용할 gateway 타입: "igw" 또는 "ngw"
    subnets   = list(string)   // 이 route table에 연결할 서브넷 ID 리스트
    tags      = map(string)    // 개별 리소스 태그
  }))
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공용 태그"
  type        = map(string)
}

variable "aws_region" {
  description = "AWS 리전 정보"
  type        = string
}

variable "igw_ids" {
  description = "외부 모듈(module.vpcs)에서 전달받은 IGW ID 목록"
  type        = list(string)
}

variable "ngw_ids" {
  description = "외부 모듈(module.nat_gateways)에서 전달받은 NAT Gateway ID 목록"
  type        = list(string)
}
