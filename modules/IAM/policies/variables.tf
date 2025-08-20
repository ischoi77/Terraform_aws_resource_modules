variable "policies" {
  description = "Policy configuration including directory and managed policy names"
  type = object({
    policy_dir                         = string
    managed_policy_names              = list(string)
    managed_service_role_policy_names = list(string)
  })
}
