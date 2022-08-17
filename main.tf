provider "aws" {
  region = local.region
  assume_role {
    role_arn = var.assume_role_arn
  }
}

### Variables ###

variable "assume_role_arn" {
  type = string
}

variable "region" {
  type = string
}

### Locals ###

data "aws_caller_identity" "current" {}

locals {
  account_id   = data.aws_caller_identity.current.account_id
  region       = var.region
  project_name = "saturn5"
  origin_id    = "s3-saturn5"
}

### S3 Bucket ###
resource "aws_s3_bucket" "main" {
  bucket = "${local.project_name}-${local.region}-${local.account_id}"
}

resource "aws_s3_bucket_acl" "default" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = aws_s3_bucket.main.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_website_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket

  index_document {
    suffix = "index.html"
  }
}

### S3 Objects ###

resource "aws_s3_object" "index" {
  bucket         = aws_s3_bucket.main.bucket
  key            = "index.html"
  content_base64 = filebase64("${path.module}/index.html")
  content_type   = "text/html"
}

resource "aws_s3_object" "saturn5" {
  bucket         = aws_s3_bucket.main.bucket
  key            = "saturn5.jpg"
  content_base64 = filebase64("${path.module}/saturn5.jpg")
  content_type   = "image/jpeg"
}

resource "aws_s3_object" "saturn5flame" {
  bucket         = aws_s3_bucket.main.bucket
  key            = "saturn5-flame.jpg"
  content_base64 = filebase64("${path.module}/saturn5-flame.jpg")
  content_type   = "image/jpeg"
}

# ### CloudFront ###

// Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "S3 CloudFront OAI"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
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
      locations        = ["BR"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # WAF Association
  web_acl_id = aws_wafv2_web_acl.cloudfront.arn
}

### CloudFront OAI ###

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.main.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_oai" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.s3_policy.json
}


### WAF ###

resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "cloudfront-waf"
  description = "Cloudfront rate based statement."
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["BR"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "friendly-rule-metric-name"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "friendly-metric-name"
    sampled_requests_enabled   = false
  }
}


### Outputs ###

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
