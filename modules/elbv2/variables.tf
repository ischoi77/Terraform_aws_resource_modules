variable "elbv2s" {
  description = "각 로드 밸런서에 대한 통합 구성"
  type = map(object({
    lb = object({
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

    target_groups = map(object({
      port        = number
      protocol    = string
      target_type = string
      vpc_name    = string
      health_check = object({
        enabled             = bool
        interval            = number
        path                = string
        protocol            = string
        timeout             = number
        unhealthy_threshold = number
        healthy_threshold   = number
      })
      tags       = map(string)
      target_id  = optional(string)
    }))

    listeners = map(object({
      port            = number
      protocol        = string
      ssl_policy      = optional(string)
      certificate_arn = optional(string)
      default_action = object({
        type              = string
        target_group_key  = string
      })
    }))

    listener_rules = optional(map(object({
      listener_key = string
      action = object({
        type              = string
        target_group_key  = string
      })
      conditions = object({
        path_patterns   = optional(list(string))
        host_headers    = optional(list(string))
        http_headers    = optional(list(object({
          name   = string
          values = list(string)
        })))
        query_strings   = optional(list(object({
          key   = optional(string)
          value = string
        })))
        source_ips      = optional(list(string))
      })
    })))

    attachments = optional(map(object({
      target_group_key = string
      target_id        = string
      port             = number
    })))
  }))
}

variable "sg_ids" {
  description = "보안 그룹 이름 → ID 매핑"
  type        = map(string)
}

variable "subnet_ids" {
  description = "서브넷 이름 → ID 매핑"
  type        = map(string)
}

variable "vpc_ids" {
  description = "VPC 이름 → ID 매핑"
  type        = map(string)
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

