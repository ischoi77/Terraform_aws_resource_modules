output "security_group_ids" {
  description = "생성된 Security Group ID 목록 (key: 보안 그룹 이름)"
  value       = { for key, sg in aws_security_group.this : key => sg.id }
}

output "ingress_rule_ids" {
  description = "생성된 Security Group Ingress Rule ID 목록"
  value       = { for key, rule in aws_security_group_rule.ingress : key => rule.id }
}

output "egress_rule_ids" {
  description = "생성된 Security Group Egress Rule ID 목록"
  value       = { for key, rule in aws_security_group_rule.egress : key => rule.id }
}
