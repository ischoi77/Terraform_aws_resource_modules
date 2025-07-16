variable "target_groups" {
  description = "타겟 그룹 변수"
  type = map(object({
    port        = number
    protocol    = string
    target_type = string
    vpc_name     = string
    health_check = object({
      enabled             = bool
      interval            = number
      path                = string
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
      healthy_threshold   = number
    })
    tags = map(string)
  }))
}

variable "common_tags" {
  type    = map(string)
  default = {}
}


variable "vpc_ids" {
  description = "VPC 이름 → ID 매핑"
  type        = map(string)
}