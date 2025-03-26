output "vpc_peering_ids" {
  description = "모듈에서 생성한 VPC 피어링 연결 ID 목록"
  value       = { for k, pc in aws_vpc_peering_connection.this : k => pc.id }
}
