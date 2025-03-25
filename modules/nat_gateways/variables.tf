variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "nat_gateway_csv_file" {
  description = <<-EOT
    NAT Gateway 생성 정보를 담은 CSV 파일의 경로.
    CSV 파일은 헤더를 포함해야 하며, 각 행은 아래 항목들을 포함해야 합니다.
      - nat_gateway_name: NAT Gateway 이름
      - subnet: NAT Gateway가 속할 서브넷 ID
      - public: NAT Gateway가 Public 인지 여부 ("true" 또는 "false")
      - allocation_id: (옵션) public이 true인 경우, 이미 할당된 EIP의 allocation_id.
        만약 값이 비어있으면 모듈 내에서 EIP를 생성하여 사용합니다.
  EOT
  type = string
}
