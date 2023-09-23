provider "aws" {
  region = "us-east-1"
  alias  = "useast1"
}

resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "cloudfront-waf"
  description = "Cloudfront rate based statement."
  scope       = "CLOUDFRONT"
  provider    = aws.useast1

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
        limit              = var.rate_limit
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = var.country_codes
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "rate-limit-metric"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "waf-metric"
    sampled_requests_enabled   = false
  }
}
