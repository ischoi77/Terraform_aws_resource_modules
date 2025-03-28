output "route_table_ids" {
  description = "생성된 route table ID 목록"
  value       = { for key, rt in aws_route_table.this : key => rt.id }
}
