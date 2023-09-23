locals {
  origin_id = "s3-saturn5"
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "S3 CloudFront OAI"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = var.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = var.elb_dns_name
    origin_id   = var.elb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-CloudFront-Auth"
      value = var.elb_auth_header
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Saturn 5 CloudFront"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = var.country_codes
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # WAF Association
  web_acl_id = var.waf_arn
}
