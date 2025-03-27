variable "aws_region" {
  type        = string
  description = "AWS 리전 정보"
}

variable "common_tags" {
  type        = map(string)
  description = "리소스 공용 태그"
}

variable "vpc_ids" {
  type        = map(string)
  description = "VPC 이름을 키로 하는 VPC ID 맵 (예: { vpc1 = \"vpc-xxxx\", ... } )"
}
