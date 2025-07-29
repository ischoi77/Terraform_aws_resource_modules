variable "user_csv_file" {
  type        = string
  description = "Path to the user CSV file"
}

variable "custom_policy_arns" {
  description = "Map of custom IAM policy names to ARNs"
  type        = map(string)
}

variable "managed_policy_arns" {
  description = "Map of AWS managed IAM policy names to ARNs"
  type        = map(string)
}

variable "common_tags" {
  type        = map(string)
  default     = {}
}



variable "group_names" {
  description = "List of valid group names (from groups module)"
  type        = list(string)
}