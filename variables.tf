variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "waf_country_codes" {
  type    = list(string)
  default = ["US", "BR"]
}

variable "waf_rate_limit" {
  type    = number
  default = 1000
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}
