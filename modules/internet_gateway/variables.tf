
variable "aws_region" {
  description = "AWS 리전 (태그에는 사용하지 않습니다)"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "vpc_ids" {
  type        = map(string)
}

variable "internet_gateways" {
  description = <<-EOT
    생성할 Internet Gateway 정보를 담은 map(object) 변수입니다.
    각 key는 Internet Gateway의 이름(예: "igw-vpc1")으로 사용되며,
    value 객체는 다음 속성을 포함합니다.
      - vpc_name: 연결할 VPC의 이름 (예: "vpc1")
      - tags    : (옵션) 추가로 적용할 태그
  EOT
  type = map(object({
    vpc_name = string
    tags     = map(string)
  }))
}