variable "elbs" {
  description = "생성할 ELB 설정 목록"
  type = map(object({
    name               = string
    availability_zones = list(string)
    listeners = list(object({
      instance_port      = number
      instance_protocol  = string
      lb_port            = number
      lb_protocol        = string
      ssl_certificate_id = optional(string)
    }))
    health_check = object({
      target              = string
      interval            = number
      timeout             = number
      unhealthy_threshold = number
      healthy_threshold   = number
    })
    subnets                     = optional(list(string))
    security_groups             = optional(list(string))
    cross_zone_load_balancing   = optional(bool)
    idle_timeout                = optional(number)
    connection_draining         = optional(bool)
    connection_draining_timeout = optional(number)
    internal                    = optional(bool)
    instances                   = optional(list(string))
    access_logs = optional(object({
      bucket        = string
      bucket_prefix = optional(string)
      enabled       = optional(bool)
      interval      = optional(number)
    }))
    tags = optional(map(string))
  }))
}
