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

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = aws_lb.main.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "cloudfront-header"
      value = "abcdef012345"
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

### Load Balancer ###

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  # Enable DNS hostnames 
  enable_dns_hostnames = true
}

### Internet Gateway ###

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-lb"
  }
}

### Route Tables ###

resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "internet-rt"
  }
}


### Subnets ###

resource "aws_subnet" "subnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "lb-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1b"

  # Auto-assign public IPv4 address
  map_public_ip_on_launch = true

  tags = {
    Name = "lb-subnet2"
  }
}

resource "aws_security_group" "allow_http_lb" {
  name        = "Allow HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sc"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "tg-balancer"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_lb" "main" {
  name               = "cached-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_lb.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_lb_listener_rule" "host_based_weighted_routing" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    http_header {
      http_header_name = "cloudfront-header"
      values           = ["abcdef012345"]
    }
  }
}


### Outputs ###

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
