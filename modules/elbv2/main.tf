/*
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-07-15
Description: AWS Elbv2 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v1.0.0
*/

locals {
  lb_security_groups = {
    for lb_key, lb in var.elbv2s :
    lb_key => [for sg_name in lb.lb.security_group_names : var.sg_ids[sg_name]]
  }

  lb_subnets = {
    for lb_key, lb in var.elbv2s :
    lb_key => [for subnet_name in lb.lb.subnet_names : var.subnet_ids[subnet_name]]
  }


  listener_entries = flatten([
    for lb_key, lb in var.elbv2s : [
      for listener_key, listener in lb.listeners : {
        key = "${lb_key}::${listener_key}"
        value = {
          lb_key           = lb_key
          port             = listener.port
          protocol         = listener.protocol
          ssl_policy       = try(listener.ssl_policy, null)
          certificate_arn  = try(listener.certificate_arn, null)
          target_group_arn = listener.default_action.target_group_name
          default_action   = listener.default_action
        }
      }
    ]
  ])

  listeners = {
    for entry in local.listener_entries :
    entry.key => entry.value
  }

listener_rule_entries = flatten([
    for lb_key, lb in var.elbv2s : (
      lb.listener_rules != null ? [
        for rule_key, rule in lb.listener_rules : {
          key = "${lb_key}::${rule.priority}"
          value = {
            listener_arn     = aws_lb_listener.this["${lb_key}::${rule.listener_key}"].arn
            priority         = rule.priority
            action           = rule.action
            target_group_arn = rule.action.target_group_name
            conditions       = rule.conditions
          }
        }
      ] : []
    )
  ])

  listener_rules = {
    for entry in local.listener_rule_entries :
    entry.key => entry.value
  }
}


resource "aws_lb" "this" {
  for_each           = var.elbv2s
  name               = each.key
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

resource "aws_lb_listener" "this" {
  for_each = local.listeners

  load_balancer_arn = aws_lb.this[each.value.lb_key].arn
  port              = each.value.port
  protocol          = each.value.protocol
  ssl_policy        = lookup(each.value, "ssl_policy", null)
  certificate_arn   = lookup(each.value, "certificate_arn", null)

  default_action {
    type             = each.value.default_action.type
    target_group_arn = var.target_group_arns[each.value.target_group_arn]
  }
}

resource "aws_lb_listener_rule" "this" {
  for_each = local.listener_rules

  listener_arn = each.value.listener_arn
  priority     = each.value.priority

  action {
    type             = each.value.action.type
    target_group_arn = var.target_group_arns[each.value.target_group_arn]
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