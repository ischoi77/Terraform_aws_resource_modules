output "route_table_ids" {
  description = "생성된 라우트 테이블 ID 목록 (키: <vpc_key>-<subnet_name>)"
  value       = { for key, rt in aws_route_table.this : key => rt.id }
}

output "route_table_association_ids" {
  description = "라우트 테이블 연결(association) ID 목록"
  value       = { for key, assoc in aws_route_table_association.this : key => assoc.id }
}
