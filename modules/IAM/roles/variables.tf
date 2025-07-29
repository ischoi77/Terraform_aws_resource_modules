variable "roles_csv_file" {
  description = "Path to roles.csv file"
  type        = string
}

# variable "inline_policies" {
#   type        = map(string)
#   description = "Map of policy name to JSON"
# }

variable "managed_policy_arns" {
  type        = map(string)
  description = "Map of policy name to ARN"
}

variable "common_tags" {
  type    = map(string)
  default = {}
}
