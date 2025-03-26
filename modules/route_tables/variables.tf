variable "vpc_id" {
  description = "Route table을 생성할 VPC ID"
  type        = string
}

variable "route_tables" {
  description = "각 route table에 대한 구성 정보"
  type = map(object({
    name    = string         // route table 이름
    vpc_name = string
    routes  = list(object({
      route_key = string      // ip_lists/<route_key>.list 파일 접두어 (파일은 destination CIDR 블록만 포함)
      gateway   = string      // 사용할 gateway 이름 (local.gateway_map 의 key 값)
    }))
    subnets = list(string)   // 외부 모듈(module.subnets)에서 전달받은 subnet_ids map의 key 값 선택
    tags    = map(string)    // 개별 리소스 태그
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


variable "vpc_ids" {
  description = "module.vpcs.vpc_ids에서 전달받은, VPC 이름을 키로 하는 VPC ID 목록"
  type        = map(string)
}

# 외부 모듈에서 전달받은 igw_ids, ngw_ids, vpc_peering_ids 는 각각 map 형식입니다.
variable "igw_ids" {
  description = "외부 모듈(module.vpcs)에서 전달받은 IGW ID map (key: gateway 이름, value: ID)"
  type        = map(string)
}

variable "ngw_ids" {
  description = "외부 모듈(module.nat_gateways)에서 전달받은 NAT Gateway ID map (key: gateway 이름, value: ID)"
  type        = map(string)
}

variable "vpc_peering_ids" {
  description = "외부 모듈에서 전달받은 VPC Peering ID map (key: gateway 이름, value: ID)"
  type        = map(string)
}

variable "subnet_ids" {
  description = "외부 모듈(module.subnets)에서 전달받은 subnet ID map (key: subnet 이름, value: subnet ID)"
  type        = map(string)
}
