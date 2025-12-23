output "instance_ids" {
  description = "키=인스턴스명, 값=EC2 Instance ID"
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "instance_arns" {
  description = "키=인스턴스명, 값=EC2 Instance ARN"
  value       = { for k, v in aws_instance.this : k => v.arn }
}

output "private_ips" {
  description = "키=인스턴스명, 값=Private IP"
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "public_ips" {
  description = "키=인스턴스명, 값=Public IP"
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "primary_network_interface_ids" {
  description = "키=인스턴스명, 값=Primary ENI ID"
  value       = { for k, v in aws_instance.this : k => v.primary_network_interface_id }
}

output "eip_allocation_ids" {
  description = "EIP 생성한 경우 allocation id"
  value       = { for k, v in aws_eip.this : k => v.id }
}

output "extra_ebs_volume_ids" {
  description = "추가 EBS 볼륨 IDs (key=instance-idx)"
  value       = { for k, v in aws_ebs_volume.extra : k => v.id }
}

output "created_eni_ids" {
  description = "별도 생성 ENI IDs (key=instance-idx)"
  value       = { for k, v in aws_network_interface.this : k => v.id }
}
