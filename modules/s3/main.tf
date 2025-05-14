resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket = each.value.name
  acl    = each.value.acl

  tags = merge(var.common_tags, each.value.tags)

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
}
