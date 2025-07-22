variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "buckets" {
  type = map(object({
    name              = string
    #acl               = string
    force_destroy     = bool
    #enable_versioning = bool
    tags              = map(string)

    logging = object({
      target_bucket = string
      target_prefix = string
    })

    lifecycle_rules = list(object({
      id        = string
      enabled   = bool
      prefix    = optional(string)
      transitions = list(object({
        days          = number
        storage_class = string
      }))
      expiration = object({
        days = number
      })
    }))

    policy_file = string
  }))
}
