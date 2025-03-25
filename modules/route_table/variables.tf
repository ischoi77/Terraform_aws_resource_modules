variable "aws_region" {
  description = "AWS 리전 (태그에는 사용하지 않습니다)"
  type        = string
}

variable "vpc_ids" {
  description = "각 VPC의 ID를 담은 map. 키는 VPC 식별자 (예: vpc1, vpc2)"
  type        = map(string)
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "subnet_csv_files" {
  description = <<-EOT
    각 VPC별 서브넷 정보를 담은 CSV 파일 경로의 map.
    키는 VPC 식별자와 일치해야 하며, CSV 파일은 헤더가 포함되어 있어야 합니다.
    CSV 파일에는 최소한 다음 컬럼이 포함되어야 합니다:
      - name : 서브넷 이름 (예: test.stg.korea.service.ap-northeast-2a)
      - cidr : 서브넷 CIDR (예: 10.0.1.0/24) (선택 사항)
  EOT
  type = map(string)
}

variable "subnet_ids" {
  description = <<-EOT
    서브넷 모듈에서 생성된 서브넷 ID의 mapping.
    각 키는 "<vpc_key>-<subnet_name>" 형식이어야 합니다.
  EOT
  type = map(string)
}
