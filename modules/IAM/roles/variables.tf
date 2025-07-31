variable "roles_csv_file" {
  description = "Path to roles.csv file"
  type        = string
}

# variable "inline_policies" {
#   type        = map(string)
#   description = "Map of policy name to JSON"
# }

variable "managed_policy_arns" {
  description = "Map of AWS managed IAM policy names to ARNs"
  type        = map(string)
}

variable "custom_policy_arns" {
  description = "Map of custom IAM policy names to ARNs"
  type        = map(string)
}

variable "managed_service_role_policy_arns" {
  description = "Map of AWS service-linked role policy ARNs"
  type        = map(string)
}

variable "managed_service_role_policy_names" {
  description = "List of AWS service-linked role policy names (to auto-map from managed_service_role_policy_arns)"
  type        = list(string)
}

variable "common_tags" {
  type    = map(string)
  default = {}
}


variable "default_path" {
  description = "Default IAM role path"
  type        = string
  default     = "/"
}