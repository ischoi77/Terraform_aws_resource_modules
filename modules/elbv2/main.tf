locals {
  # 보안 그룹 ID 매핑
  lb_security_groups = {
    for lb_key, lb in var.elbv2s :
    lb_key => [for sg_name in lb.lb.security_group_names : var.sg_ids[sg_name]]
  }

  # 서브넷 ID 매핑
  lb_subnets = {
    for lb_key, lb in var.elbv2s :
    lb_key => [for subnet_name in lb.lb.subnet_names : var.subnet_ids[subnet_name]]
  }

  # Target Groups
  target_groups = merge([
    for lb_key, lb in var.elbv2s : {
      for tg_key, tg in lb.target_groups :
      "${lb_key}::${tg_key}" => merge(tg, { lb_key = lb_key })
    }
  ]...)

  # Listeners
  listeners = merge([
    for lb_key, lb in var.elbv2s : {
      for listener_key, l in lb.listeners :
      "${lb_key}::${listener_key}" => merge(l, {
        lb_key           = lb_key
        target_group_arn = aws_lb_target_group.this["${lb_key}::${l.default_action.target_group_key}"].arn
      })
    }
  ]...)

  # Listener Rules
  listener_rules = merge([
    for lb_key, lb in var.elbv2s : (
      lb.listener_rules != null ? {
        for rule_key, rule in lb.listener_rules :
        "${lb_key}::${rule_key}" => merge(rule, {
          lb_key           = lb_key
          listener_arn     = aws_lb_listener.this["${lb_key}::${rule.listener_key}"].arn
          target_group_arn = aws_lb_target_group.this["${lb_key}::${rule.action.target_group_key}"].arn
        })
      } : {}
    )
  ]...)

  # 기본 연결용 Attachments
  default_target_attachments = merge(flatten([
    for lb_key, lb in var.elbv2s : [
      for target_group_key in distinct(concat(
        [for l in values(lb.listeners) : l.default_action.target_group_key],
        lb.listener_rules != null ? [for r in values(lb.listener_rules) : r.action.target_group_key] : []
      )) : [
        {
          "${lb_key}::${target_group_key}::default" => {
            lb_key           = lb_key,
            target_group_key = target_group_key,
            target_group_arn = aws_lb_target_group.this["${lb_key}::${target_group_key}"].arn,
            target_id        = try(var.elbv2s[lb_key].target_groups[target_group_key].target_id, null),
            port             = var.elbv2s[lb_key].target_groups[target_group_key].port
          }
        }
      ]
    ]
  ])...)

  # 수동 Attachments
  manual_target_attachments = merge(flatten([
    for lb_key, lb in var.elbv2s : (
      lb.attachments != null ? [
        for name, attachment in lb.attachments : {
          "${lb_key}::${attachment.target_group_key}::${name}" => {
            lb_key           = lb_key
            target_group_key = attachment.target_group_key
            target_group_arn = aws_lb_target_group.this["${lb_key}::${attachment.target_group_key}"].arn
            target_id        = attachment.target_id
            port             = attachment.port
          }
        }
      ] : []
    )
  ])...)

  all_attachments = merge(local.default_target_attachments, local.manual_target_attachments)
}

resource "aws_lb" "this" {
  for_each           = var.elbv2s
  name               = each.value.lb.name
  internal           = each.value.lb.internal
  load_balancer_type = each.value.lb.load_balancer_type
  security_groups    = local.lb_security_groups[each.key]
  subnets            = local.lb_subnets[each.key]
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
  for_each = local.target_groups

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
  for_each = local.listeners

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
  for_each = local.listener_rules

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = each.value.target_group_arn
  }

  dynamic "condition" {
    for_each = each.value.conditions.path_patterns != null ? each.value.conditions.path_patterns : []
    content {
      path_pattern {
        values = [condition.value]
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.host_headers != null ? each.value.conditions.host_headers : []
    content {
      host_header {
        values = [condition.value]
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.http_headers != null ? each.value.conditions.http_headers : []
    content {
      http_header {
        http_header_name = condition.value.name
        values           = condition.value.values
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.query_strings != null ? each.value.conditions.query_strings : []
    content {
      query_string {
        key   = lookup(condition.value, "key", null)
        value = condition.value.value
      }
    }
  }

  dynamic "condition" {
    for_each = each.value.conditions.source_ips != null ? each.value.conditions.source_ips : []
    content {
      source_ip {
        values = [condition.value]
      }
    }
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for k, v in local.all_attachments : k => v if v.target_id != null
  }

  target_group_arn = each.value.target_group_arn
  target_id        = each.value.target_id
  port             = each.value.port

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [target_id]
  }
}

