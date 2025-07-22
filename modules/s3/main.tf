resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket        = each.value.name
  force_destroy = each.value.force_destroy
  tags          = merge(var.common_tags, each.value.tags)
}

# resource "aws_s3_bucket_ownership_controls" "this" {
#   for_each = var.buckets

#   bucket = aws_s3_bucket.this[each.key].id
#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

# resource "aws_s3_bucket_acl" "this" {
#   for_each = var.buckets

#   depends_on = [aws_s3_bucket_ownership_controls.this]

#   bucket = aws_s3_bucket.this[each.key].id
#   acl    = each.value.acl
# }

# resource "aws_s3_bucket_versioning" "this" {
#   for_each = {
#     for k, v in var.buckets : k => v if v.enable_versioning
#   }

#   bucket = aws_s3_bucket.this[each.key].id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

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
  policy = file("${path.root}/s3_policy/${each.value.policy_file}")
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
