output "nat_gateway_ids" {
  description = "생성된 NAT Gateway ID 목록 (key: nat_gateway_name)"
  value       = { for key, ng in aws_nat_gateway.this : key => ng.id }
}

output "eip_ids" {
  description = "생성된 Elastic IP ID 목록 (key: nat_gateway_name, 해당 NAT Gateway에 대해 생성된 경우)"
  value       = { for key, eip in aws_eip.this : key => eip.id }
}
