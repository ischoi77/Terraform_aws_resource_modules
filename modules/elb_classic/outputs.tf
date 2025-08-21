output "elb_names" {
  value = { for k, elb in aws_elb.this : k => elb.name }
}

output "elb_dns_names" {
  value = { for k, elb in aws_elb.this : k => elb.dns_name }
}
