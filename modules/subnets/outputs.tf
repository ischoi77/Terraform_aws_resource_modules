output "subnet_ids" {
  description = "생성된 서브넷 ID 목록 (key: <vpc_key>-<subnet_name>)"
  value       = { for key, subnet in aws_subnet.this : key => subnet.id }
}
