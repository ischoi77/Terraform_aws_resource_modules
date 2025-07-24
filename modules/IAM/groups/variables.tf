variable "group_csv_file" {
  description = "Path to CSV file defining group name and policy names"
  type        = string
}

variable "policy_arns" {
  description = "Map of policy name => policy ARN (from policies module)"
  type        = map(string)
}
