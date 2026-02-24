resource "aws_wafv2_web_acl" "rate_limit" {
  name  = "RateLimitWebACL"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    sampled_requests_enabled   = true
    cloudwatch_metrics_enabled = true
    metric_name                = "RateLimitWebACL"
  }

  rule {
    name     = "RateLimitRule"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 500
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      sampled_requests_enabled   = true
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.fqdn}-OAC"
  description                       = "Origin Access Control for ${var.fqdn}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  aliases = [for site in var.websites : site.fqdn]

  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Default cache behavior for first site
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimised
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # None (no headers/cookies/query strings)
  }

  # Additional cache behaviors for other sites
  dynamic "ordered_cache_behavior" {
    for_each = slice(var.websites, 1, length(var.websites))
    content {
      path_pattern           = "${ordered_cache_behavior.value.path_prefix}/*"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      compress               = true
      target_origin_id       = "S3Origin"
      viewer_protocol_policy = "redirect-to-https"
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimised
      origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf" # None (no headers/cookies/query strings)
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.certificate.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.rate_limit.arn
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.distribution.arn
          }
        }
      }
    ]
  })
}

resource "aws_route53_record" "dns" {
  for_each = { for site in var.websites : site.fqdn => site }
  
  zone_id = each.value.zone_id  # ✅ Use individual zone ID for each domain
  name    = each.value.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID
    evaluate_target_health = true
  }
}
