variable "project_name" {
  type = string
}

variable "waf_arn" {
  type = string
}

variable "elb_dns_name" {
  type = string
}

variable "elb_auth_header" {
  type = string
}

variable "bucket_regional_domain_name" {
  type = string
}

variable "country_codes" {
  type = list(string)
}
