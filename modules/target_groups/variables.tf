variable "target_groups" {
  description = "다중 타겟을 위한 타겟그룹 설정"
  type = map(object({
    port         = number
    protocol     = string
    vpc_name      = string
    target_type  = optional(string, "instance")
    health_check = optional(object({
      enabled             = optional(bool)
      interval            = optional(number)
      path                = optional(string)
      protocol            = optional(string)
      timeout             = optional(number)
      unhealthy_threshold = optional(number)
      healthy_threshold   = optional(number)
    }), {})
    targets = optional(list(object({      # ✅ target_id → targets
      target_id = string
      port      = number
    })), [])
    tags = optional(map(string), {})
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

variable "instance_ids" {
  description = "Instance 이름 → ID 매핑"
  type        = map(string)
}