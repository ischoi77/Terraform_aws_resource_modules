# variable "policy_dir" {
#   description = "Relative path to directory containing JSON policy files"
#   type        = string
# }


variable "policies" {
  description = <<EOT
Unified policy config including root directory and managed policy names:
{
  policy_dir = "path/to/policies"

  user = {
    aws_managed = [...]
  }

  group = {
    aws_managed = [...]
  }

  role = {
    aws_managed = [...]
  }
}
EOT

  type = object({
    policy_dir = string

    user  = optional(object({ aws_managed = optional(list(string), []) }), {})
    group = optional(object({ aws_managed = optional(list(string), []) }), {})
    role  = optional(object({ aws_managed = optional(list(string), []) }), {})
  })
}
