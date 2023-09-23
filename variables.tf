variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "waf_country_codes" {
  type    = list(string)
  default = ["US", "BR"]
}
