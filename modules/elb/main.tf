resource "aws_elb" "this" {
  for_each = var.elbs

  name               = each.value.name
  availability_zones = each.value.availability_zones
  security_groups    = lookup(each.value, "security_groups", null)
  subnets            = lookup(each.value, "subnets", null)

  dynamic "listener" {
    for_each = each.value.listeners
    content {
      instance_port      = listener.value.instance_port
      instance_protocol  = listener.value.instance_protocol
      lb_port            = listener.value.lb_port
      lb_protocol        = listener.value.lb_protocol
      ssl_certificate_id = lookup(listener.value, "ssl_certificate_id", null)
    }
  }
  
  health_check {
    target              = each.value.health_check.target
    interval            = each.value.health_check.interval
    timeout             = each.value.health_check.timeout
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    healthy_threshold   = each.value.health_check.healthy_threshold
  }

  cross_zone_load_balancing   = lookup(each.value, "cross_zone_load_balancing", true)
  idle_timeout                = lookup(each.value, "idle_timeout", 60)
  connection_draining         = lookup(each.value, "connection_draining", false)
  connection_draining_timeout = lookup(each.value, "connection_draining_timeout", 300)
  internal                    = lookup(each.value, "internal", false)

  dynamic "access_logs" {
    for_each = lookup(each.value, "access_logs", null) == null ? [] : [each.value.access_logs]
    content {
      bucket        = access_logs.value.bucket
      bucket_prefix = lookup(access_logs.value, "bucket_prefix", null)
      enabled       = lookup(access_logs.value, "enabled", true)
      interval      = lookup(access_logs.value, "interval", null)
    }
  }

  tags = merge(var.common_tags, lookup(each.value, "tags", {}))
}
