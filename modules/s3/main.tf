resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.value.name
  acl    = each.value.acl != null ? [each.value.acl] : null

  force_destroy = each.value.force_destroy
  tags          = merge(var.common_tags, each.value.tags)

  dynamic "versioning" {
    for_each = each.value.enable_versioning ? [1] : []
    content {
      enabled = true
    }
  }

  dynamic "logging" {
    for_each = each.value.logging != null ? [each.value.logging] : []
    content {
      target_bucket = logging.value.target_bucket
      target_prefix = logging.value.target_prefix
    }
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_rules
    content {
      id      = lifecycle_rule.value.id
      enabled = lifecycle_rule.value.enabled
      prefix  = lookup(lifecycle_rule.value, "prefix", null)

      dynamic "transition" {
        for_each = lifecycle_rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lifecycle_rule.value.expiration != null ? [lifecycle_rule.value.expiration] : []
        content {
          days = expiration.value.days
        }
      }
    }
  }

  dynamic "server_side_encryption_configuration" {
    for_each = each.value.sse_config != null ? [each.value.sse_config] : []
    content {
      rule {
        apply_server_side_encryption_by_default {
          sse_algorithm     = sse_config.value.sse_algorithm
          kms_master_key_id = lookup(sse_config.value, "kms_master_key_id", null)
        }
      }
    }
  }

  dynamic "cors_rule" {
    for_each = each.value.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = lookup(cors_rule.value, "expose_headers", null)
      max_age_seconds = lookup(cors_rule.value, "max_age_seconds", null)
    }
  }

  dynamic "website" {
    for_each = each.value.website != null ? [each.value.website] : []
    content {
      index_document = website.value.index_document
      error_document = website.value.error_document
    }
  }

  policy = each.value.policy_file != null ? file("${path.root}/policy_files/${each.value.policy_file}") : null
}
