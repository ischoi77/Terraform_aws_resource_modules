variable "aws_region" {
  description = "AWS 리전"
  type        = string
}

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "buckets" {
  description = "S3 bucket definitions"
  type = map(object({
    name              = string
    acl               = string
    tags              = map(string)
    enable_versioning = bool
    logging = object({
      target_bucket = string
      target_prefix = string
    })
  }))
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
}
