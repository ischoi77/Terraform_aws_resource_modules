variable "aws_region" {
  description = "AWS 리전 (서브넷 생성 시 사용)"
  type        = string
}

variable "vpc_ids" {
  description = "서브넷이 속할 각 VPC의 ID를 담은 map. key는 VPC 식별자 (예: vpc1, vpc2)"
  type        = map(string)
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "subnet_csv_files" {
  description = <<-EOT
    각 VPC별 서브넷 정보를 담은 CSV 파일 경로의 map.
    key는 VPC 식별자와 일치해야 하며, value는 해당 VPC의 서브넷 CSV 파일 경로입니다.
    CSV 파일은 헤더를 포함해야 하며, 최소한 다음 컬럼을 포함합니다.
      - name : 서브넷 이름 (예: test.stg.korea.service.ap-northeast-2a)
      - cidr : 서브넷 CIDR (예: 10.0.1.0/24)
  EOT
  type = map(string)
}