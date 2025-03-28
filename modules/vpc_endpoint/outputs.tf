output "vpc_endpoint_ids" {
  description = "생성된 VPC Endpoint ID 목록 (key: 엔드포인트 이름)"
  value       = { for key, ep in aws_vpc_endpoint.this : key => ep.id }
}