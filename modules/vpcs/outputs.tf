output "vpc_ids" {
  description = "생성된 VPC ID 목록 (key: 리소스 이름)"
  value       = { for key, vpc in aws_vpc.this : key => vpc.id }
}


output "vpc_ipv4_cidr_association_ids" {
  description = "VPC에 추가된 IPv4 CIDR 블록 할당 ID 목록"
  value       = { for key, assoc in aws_vpc_ipv4_cidr_block_association.this : key => assoc.id }
}