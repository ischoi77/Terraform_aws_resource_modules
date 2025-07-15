output "load_balancers" {
  description = "각 로드 밸런서 이름별 정보"
  value = {
    for lb_key, lb in aws_lb.this :
    lb_key => {
      arn      = lb.arn
      dns_name = lb.dns_name
      zone_id  = lb.zone_id
    }
  }
}

output "target_groups" {
  description = "각 ELB별 Target Group 정보"
  value = {
    for tg_key, tg in aws_lb_target_group.this :
    tg_key => {
      arn     = tg.arn
      name    = tg.name
      port    = tg.port
      vpc_id  = tg.vpc_id
    }
  }
}

output "listeners" {
  description = "각 ELB별 Listener 정보"
  value = {
    for l_key, l in aws_lb_listener.this :
    l_key => {
      arn     = l.arn
      port    = l.port
      protocol = l.protocol
    }
  }
}

output "listener_rules" {
  description = "각 Listener Rule 정보"
  value = {
    for rule_key, rule in aws_lb_listener_rule.this :
    rule_key => {
      arn      = rule.arn
      priority = rule.priority
    }
  }
}

output "target_group_attachments" {
  description = "Target Group에 연결된 Attachment 정보"
  value = {
    for att_key, att in aws_lb_target_group_attachment.this :
    att_key => {
      target_group_arn = att.target_group_arn
      target_id        = att.target_id
      port             = att.port
    }
  }
}
