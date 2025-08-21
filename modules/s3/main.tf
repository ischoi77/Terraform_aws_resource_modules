/*
Title: 대규모 infra 구성 및 관리를 위한 AWS 리소스 모듈
Author: 최인석(Choi In-seok)
Email: ischoi77@gmail.com, knight7711@naver.com
Created: 2025-03-24
Description: AWS S3 모듈 정의
repo_url: https://github.com/ischoi77/Terraform_aws_resource_modules
Version: v1.0.0
*/

resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket        = each.value.name
  force_destroy = each.value.force_destroy
  tags          = merge(var.common_tags, each.value.tags)
}

resource "aws_s3_bucket_logging" "this" {
  for_each = {
    for k, v in var.buckets : k => v if v.logging != null
  }

  bucket        = aws_s3_bucket.this[each.key].id
  target_bucket = each.value.logging.target_bucket
  target_prefix = each.value.logging.target_prefix
}

resource "aws_s3_bucket_policy" "this" {
  for_each = {
    for k, v in var.buckets : k => v if v.policy_file != null
  }

  bucket = aws_s3_bucket.this[each.key].id
  policy = file("${path.root}/policy_files/${each.value.policy_file}")
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for k, v in var.buckets : k => v if length(v.lifecycle_rules) > 0
  }

  bucket = aws_s3_bucket.this[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = lookup(rule.value, "prefix", "")
      }

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration != null ? [rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }
}
