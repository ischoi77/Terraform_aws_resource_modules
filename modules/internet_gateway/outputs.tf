output "internet_gateway_ids" {
  description = "생성된 Internet Gateway ID 목록 (key: IGW 이름)"
  value       = { for key, igw in aws_internet_gateway.this : key => igw.id }
}
