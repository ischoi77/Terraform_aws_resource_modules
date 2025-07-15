# variable "aws_region" {
#   description = "AWS 리전"
#   type        = string
# }

variable "common_tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
}

variable "sg_ids" {
  description = "보안그룹 ID 매핑"
  type = map(string)
}

variable "subnet_ids" {
  description = "서브넷 이름 → ID 매핑"
  type        = map(string)
}

variable "elbv2s" {
  type = map(object({
    lb = object({
      name                        = string
      internal                    = bool
      load_balancer_type          = string
      security_group_names        = list(string)
      subnet_names                = list(string)
      enable_deletion_protection = bool
      ip_address_type             = string
      idle_timeout                = number
      drop_invalid_header_fields = bool
      access_logs = optional(object({
        bucket  = string
        prefix  = string
        enabled = bool
      }))
      tags = map(string)
    })

    listeners = map(object({
      port              = number
      protocol          = string
      ssl_policy        = optional(string)
      certificate_arn   = optional(string)
      default_action = object({
        type             = string
        target_group_key = string
      })
    }))

    listener_rules = optional(map(object({
      listener_key         = string
      priority             = number
      action = object({
        type             = string
        target_group_key = string
      })
      condition_path_patterns = list(string)
    })))

    target_groups = map(object({
      name        = string
      port        = number
      protocol    = string
      target_type = string
      vpc_id      = string
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

    attachments = optional(map(object({
      target_group_key = string
      target_id        = string
      port             = number
    })))
  }))
}


