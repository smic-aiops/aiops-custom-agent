locals {
  control_site_domain      = "${var.control_subdomain}.${local.hosted_zone_name_input}"
  control_site_bucket_name = "${local.name_prefix}-${replace(local.hosted_zone_name_input, ".", "-")}-control-site"
  control_site_enabled     = var.enable_service_control
  sulu_control_api_base_url_effective = trim(
    coalesce(
      var.sulu_control_api_base_url != "" ? var.sulu_control_api_base_url : null,
      try(aws_apigatewayv2_stage.sulu_control[0].invoke_url, null),
      ""
    ),
    "/"
  )
  service_control_api_base_url_effective = trim(
    coalesce(
      var.service_control_api_base_url != "" ? var.service_control_api_base_url : null,
      try(aws_apigatewayv2_stage.service_control[0].invoke_url, null),
      ""
    ),
    "/"
  )
  control_api_base_url_effective = local.service_control_api_base_url_effective != "" ? local.service_control_api_base_url_effective : local.sulu_control_api_base_url_effective
  keycloak_base_url_effective = coalesce(
    var.keycloak_base_url != null && var.keycloak_base_url != "" ? var.keycloak_base_url : null,
    "https://keycloak.${local.hosted_zone_name_input}"
  )
  control_site_keycloak_realm = coalesce(
    var.keycloak_realm != null && var.keycloak_realm != "" ? var.keycloak_realm : null,
    "master"
  )
  service_control_keycloak_client_id_effective = coalesce(
    var.service_control_keycloak_client_id != null && var.service_control_keycloak_client_id != "" ? var.service_control_keycloak_client_id : null,
    "service-control"
  )
  service_control_autostop_flags = {
    keycloak       = var.enable_keycloak_autostop
    zulip          = var.enable_zulip_autostop
    growi          = var.enable_growi_autostop
    odoo           = var.enable_odoo_autostop
    orangehrm      = var.enable_orangehrm_autostop
    "cmdbuild-r2u" = var.enable_cmdbuild_r2u_autostop
    n8n            = var.enable_n8n_autostop
    sulu           = var.enable_sulu_autostop
    "exastro-web"  = var.enable_exastro_web_autostop
    "exastro-api"  = var.enable_exastro_api_autostop
    gitlab         = var.enable_gitlab_autostop
    pgadmin        = var.enable_pgadmin_autostop
    phpmyadmin     = var.enable_phpmyadmin_autostop
  }
  control_site_index = templatefile("${path.module}/templates/control-index.html.tftpl", {
    api_base_url                   = local.control_api_base_url_effective,
    keycloak_base_url              = local.keycloak_base_url_effective,
    keycloak_realm                 = local.control_site_keycloak_realm,
    keycloak_client_id             = local.service_control_keycloak_client_id_effective,
    service_control_autostop_flags = jsonencode(local.service_control_autostop_flags)
  })
  wildcard_cf_cert_name = "${local.name_prefix}-cf-wildcard-cert"
  control_site_aliases  = [local.control_site_domain]
}

resource "aws_acm_certificate" "cloudfront_wildcard" {
  provider = aws.us_east_1
  count    = local.control_site_enabled ? 1 : 0

  domain_name       = "*.${local.hosted_zone_name_input}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.tags, { Name = local.wildcard_cf_cert_name })
}

resource "aws_route53_record" "cloudfront_wildcard_validation" {
  for_each = local.control_site_enabled ? {
    for dvo in aws_acm_certificate.cloudfront_wildcard[0].domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id         = local.hosted_zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  allow_overwrite = true
  ttl             = 300
}

resource "aws_acm_certificate_validation" "cloudfront_wildcard" {
  provider = aws.us_east_1
  count    = local.control_site_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.cloudfront_wildcard[0].arn
  validation_record_fqdns = [for r in aws_route53_record.cloudfront_wildcard_validation : r.fqdn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "control_site" {
  count  = local.control_site_enabled ? 1 : 0
  bucket = local.control_site_bucket_name

  tags = merge(local.tags, { Name = "${local.name_prefix}-control-site-s3" })
}

resource "aws_s3_bucket_ownership_controls" "control_site" {
  count  = local.control_site_enabled ? 1 : 0
  bucket = aws_s3_bucket.control_site[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "control_site" {
  count  = local.control_site_enabled ? 1 : 0
  bucket = aws_s3_bucket.control_site[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "control_site" {
  count  = local.control_site_enabled ? 1 : 0
  bucket = aws_s3_bucket.control_site[0].id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_object" "control_index" {
  count         = local.control_site_enabled ? 1 : 0
  bucket        = aws_s3_bucket.control_site[0].id
  key           = "index.html"
  content       = local.control_site_index
  content_type  = "text/html"
  cache_control = "no-store, no-cache, must-revalidate"

  depends_on = [
    aws_s3_bucket_public_access_block.control_site,
    aws_s3_bucket_ownership_controls.control_site
  ]
}

resource "aws_s3_object" "control_favicon" {
  count         = local.control_site_enabled ? 1 : 0
  bucket        = aws_s3_bucket.control_site[0].id
  key           = "favicon.ico"
  source        = "${path.module}/templates/favicon.ico"
  content_type  = "image/x-icon"
  cache_control = "public, max-age=86400"

  depends_on = [
    aws_s3_bucket_public_access_block.control_site,
    aws_s3_bucket_ownership_controls.control_site
  ]
}

resource "aws_cloudfront_origin_access_control" "control_site" {
  count                             = local.control_site_enabled ? 1 : 0
  name                              = "${local.name_prefix}-control-site-oac"
  description                       = "OAC for control site bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "control_site" {
  count = local.control_site_enabled ? 1 : 0

  enabled             = true
  default_root_object = "index.html"
  aliases             = local.control_site_aliases

  origin {
    domain_name              = aws_s3_bucket.control_site[0].bucket_regional_domain_name
    origin_id                = "s3-control-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.control_site[0].id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "s3-control-site"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP", "VN"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cloudfront_wildcard[0].certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-control-site-cf" })

  depends_on = [aws_acm_certificate_validation.cloudfront_wildcard]
}

resource "aws_s3_bucket_policy" "control_site" {
  count  = local.control_site_enabled ? 1 : 0
  bucket = aws_s3_bucket.control_site[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.control_site[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.control_site[0].arn
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.control_site,
    aws_s3_bucket_ownership_controls.control_site,
    aws_cloudfront_distribution.control_site
  ]
}

resource "aws_route53_record" "control_site_alias" {
  count   = local.control_site_enabled ? 1 : 0
  zone_id = local.hosted_zone_id
  name    = local.control_site_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.control_site[0].domain_name
    zone_id                = aws_cloudfront_distribution.control_site[0].hosted_zone_id
    evaluate_target_health = false
  }
}
