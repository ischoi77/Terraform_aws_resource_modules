output "custom_policy_arns" {
  value = {
    for k, v in aws_iam_policy.this :
    k => v.arn
  }
}

output "custom_policy_json_map" {
  value = {
    for k, v in local.custom_policy_map :
    k => v.policy
  }
}

output "skipped_policy_names" {
  value = local.skipped_policy_names
}

output "managed_policy_arns" {
  value = local.managed_policy_arns
}

output "managed_service_role_policy_arns" {
  value = local.managed_service_role_policy_arns
}


output "managed_service_role_policy_names" {
  description = "List of managed service-linked policy names used in this module"
  value       = var.policies.managed_service_role_policy_names
}