output "security_group_ids" {
  description = "생성된 Security Group ID 목록 (key: 보안 그룹 이름)"
  value       = { for key, sg in aws_security_group.this : key => sg.id }
}
