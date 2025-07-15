resource "aws_lb" "this" {
  for_each                   = var.elbv2s
  name                       = each.value.lb.name
  internal                   = each.value.lb.internal
  load_balancer_type         = each.value.lb.load_balancer_type
  security_groups = [
    for name in each.value.lb.security_group_names : var.sg_ids[name]
  ]
  subnets = [
    for name in each.value.lb.subnet_names : var.subnet_ids[name]
  ]
  enable_deletion_protection = each.value.lb.enable_deletion_protection
  ip_address_type            = each.value.lb.ip_address_type
  idle_timeout               = each.value.lb.idle_timeout
  drop_invalid_header_fields = each.value.lb.drop_invalid_header_fields
  tags = merge(each.value.lb.tags, var.common_tags)

  dynamic "access_logs" {
    for_each = each.value.lb.access_logs != null ? [each.value.lb.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      prefix  = access_logs.value.prefix
      enabled = access_logs.value.enabled
    }
  }
}

resource "aws_lb_target_group" "this" {
  for_each = merge([
    for lb_key, lb in var.elbv2s : {
      for tg_key, tg in lb.target_groups :
      "${lb_key}::${tg_key}" => merge(tg, { lb_key = lb_key })
    }
  ]...)

  name        = each.value.name
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = each.value.vpc_id

  health_check {
    enabled             = each.value.health_check.enabled
    interval            = each.value.health_check.interval
    path                = each.value.health_check.path
    protocol            = each.value.health_check.protocol
    timeout             = each.value.health_check.timeout
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
    healthy_threshold   = each.value.health_check.healthy_threshold
  }

  tags = merge(each.value.tags, var.common_tags)
}


resource "aws_lb_listener" "this" {
  for_each = merge([
    for lb_key, lb in var.elbv2s : {
      for l_key, listener in lb.listeners :
      "${lb_key}::${l_key}" => merge(listener, {
        lb_key = lb_key
        target_group_arn = aws_lb_target_group.this["${lb_key}::${listener.default_action.target_group_key}"].arn
      })
    }
  ]...)

  load_balancer_arn = aws_lb.this[each.value.lb_key].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  default_action {
    type             = each.value.default_action.type
    target_group_arn = each.value.target_group_arn
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = merge([
    for lb_key, lb in var.elbv2s : (
      lb.listener_rules != null ? {
        for rule_key, rule in lb.listener_rules :
        "${lb_key}::${rule_key}" => merge(rule, {
          lb_key              = lb_key
          listener_arn        = aws_lb_listener.this["${lb_key}::${rule.listener_key}"].arn
          target_group_arn    = aws_lb_target_group.this["${lb_key}::${rule.action.target_group_key}"].arn
        })
      } : {}
    )
  ]...)

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = each.value.target_group_arn
  }

  dynamic "condition" {
    for_each = each.value.condition_path_patterns
    content {
      path_pattern {
        values = [condition.value]
      }
    }
  }
}
