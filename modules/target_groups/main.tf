locals {
  tg_attachment_entries = [
    for tg_name, tg in var.target_groups : [
      for idx, target in tg.targets : {
        key = "${tg_name}-${idx}"
        value = {
          target_group_name = tg_name
          target_id         = target.target_id
          port              = target.port
        }
      }
    ]
  ] |> flatten()

  target_group_attachments = {
    for entry in local.tg_attachment_entries :
    entry.key => entry.value
  }
}


resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = each.key
  port        = each.value.port
  protocol    = each.value.protocol
  target_type = each.value.target_type
  vpc_id      = var.vpc_ids[each.value.vpc_name]

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


resource "aws_lb_target_group_attachment" "this" {
  for_each = local.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_name].arn
  target_id        = each.value.target_id
  port             = each.value.port

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [target_id]
  }
}
