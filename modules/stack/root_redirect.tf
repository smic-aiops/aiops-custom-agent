locals {
  root_redirect_enabled = var.root_redirect_target_url != null && trim(var.root_redirect_target_url) != "" && local.hosted_zone_name_input != null && local.hosted_zone_id != null
  root_redirect_target  = trim(var.root_redirect_target_url)
  redirect_domains      = local.root_redirect_enabled ? { root = local.hosted_zone_name_input, www = "www.${local.hosted_zone_name_input}" } : {}
  s3_website_zone_ids = {
    "ap-northeast-1" = "Z2M4EHUR26P7ZW"
  }
  redirect_s3_zone_id = lookup(local.s3_website_zone_ids, var.region, "Z2M4EHUR26P7ZW")
}

resource "aws_s3_bucket" "redirect" {
  for_each = local.redirect_domains

  bucket        = each.value
  force_destroy = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-${each.key}-redirect-s3" })
}

resource "aws_s3_bucket_ownership_controls" "redirect" {
  for_each = aws_s3_bucket.redirect

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "redirect" {
  for_each = aws_s3_bucket.redirect

  bucket                  = each.value.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "redirect" {
  for_each = aws_s3_bucket.redirect

  bucket = each.value.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_object" "redirect_index" {
  for_each = aws_s3_bucket.redirect

  bucket           = each.value.id
  key              = "index.html"
  content          = ""
  content_type     = "text/html"
  website_redirect = local.root_redirect_target
  acl              = "public-read"

  depends_on = [
    aws_s3_bucket_public_access_block.redirect,
    aws_s3_bucket_ownership_controls.redirect
  ]
}

resource "aws_s3_bucket_policy" "redirect" {
  for_each = aws_s3_bucket.redirect

  bucket = each.value.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${each.value.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.redirect]
}

resource "aws_route53_record" "root_redirect" {
  for_each = local.redirect_domains

  zone_id = local.hosted_zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.redirect[each.key].website_domain
    zone_id                = local.redirect_s3_zone_id
    evaluate_target_health = false
  }
}
