variable "aws_region" {
  description = "AWS 리전 (태그에는 사용하지 않습니다)"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "vpc_endpoints" {
  description = <<-EOT
    생성할 VPC Endpoint 정보를 담은 map(object) 변수입니다.
    각 key는 엔드포인트 이름(예: "s3-endpoint")로 사용되며,
    value 객체는 아래 속성들을 포함합니다.
      - vpc_name             : string, 엔드포인트가 생성될 VPC의 이름 var.vpc_ids 에서 이름으로 조회
      - service_name        : string, 서비스 이름 (예: "com.amazonaws.us-west-2.s3")
      - vpc_endpoint_type   : string, 엔드포인트 유형 ("Gateway", "Interface", 또는 "GatewayLoadBalancer")
      - route_table_names   : (옵션, Gateway 유형) list(string), 사용할 라우트 테이블 이름 리스트
      - subnet_names        : (옵션, Interface 유형) list(string), 사용할 서브넷 이름 리스트
      - security_group_names: (옵션, Interface 유형) list(string), 사용할 보안 그룹 이름 리스트  
                                 (값이 비어있으면 null 처리되어 리소스 생성 후 별도 입력할 수 있음)
      - private_dns_enabled : (옵션, Interface 유형) bool, Private DNS 사용 여부 (기본값 false)
      - tags                : map(string), 엔드포인트에 추가로 적용할 태그
  EOT
  type = map(object({
    vpc_name             = string
    service_name         = string
    vpc_endpoint_type    = string
    route_table_names    = optional(list(string))
    subnet_names         = optional(list(string))
    security_group_names = optional(list(string))
    private_dns_enabled  = optional(bool, false)
    policy               = optional(any) # map 형식으로 policy 받음

    tags                 = map(string)
  }))
}

variable "subnet_map" {
  description = <<-EOT
    서브넷 모듈에서 생성된 서브넷 ID 매핑입니다.
    key는 서브넷 이름 (예: "test.stg.korea.service.ap-northeast-2a")이고,
    value는 해당 서브넷의 ID입니다.
  EOT
  type = map(string)
}

variable "route_table_map" {
  description = <<-EOT
    라우트 테이블 모듈에서 생성된 라우트 테이블 ID 매핑입니다.
    key는 라우트 테이블 이름 (예: "test.stg.korea.service.ap-northeast-2a.rt")이고,
    value는 해당 라우트 테이블의 ID입니다.
  EOT
  type = map(string)
}

variable "security_group_map" {
  description = <<-EOT
    보안 그룹 모듈에서 생성된 보안 그룹 ID 매핑입니다.
    key는 보안 그룹 이름 (예: "web-sg")이고,
    value는 해당 보안 그룹의 ID입니다.
  EOT
  type = map(string)
}

variable "vpc_ids" {
  type        = map(string)
}