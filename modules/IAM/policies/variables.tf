variable "policy_dir" {
  description = "Relative path to directory containing JSON policy files"
  type        = string
}


variable "policies" {
  description = <<EOT
Unified policy config:
{
  user = {
    aws_managed = ["AmazonEC2ReadOnlyAccess"]
  },
  group = {
    aws_managed = ["AdministratorAccess"]
  },
  role = {
    aws_managed = ["AmazonS3FullAccess"]
  }
}
EOT
  type = object({
    user  = optional(object({ aws_managed = optional(list(string), []) }), {}),
    group = optional(object({ aws_managed = optional(list(string), []) }), {}),
    role  = optional(object({ aws_managed = optional(list(string), []) }), {})
  })
  default = {}
}