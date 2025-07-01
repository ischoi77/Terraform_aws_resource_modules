variable "user_csv_file" {
  type        = string
  description = "Path to the user CSV file"
}

variable "policy_arns" {
  type        = map(string)
  description = "Map of policy name to ARN, from policies module output"
}

variable "common_tags" {
  type        = map(string)
  default     = {}
}
