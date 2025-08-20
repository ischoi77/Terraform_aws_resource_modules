variable "group_csv_file" {
  description = "Path to CSV file defining group name and policy names"
  type        = string
}

variable "custom_policy_arns" {
  description = "Map of custom IAM policy names to ARNs"
  type        = map(string)
}

variable "managed_policy_arns" {
  description = "Map of AWS managed IAM policy names to ARNs"
  type        = map(string)
}