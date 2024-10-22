variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "enable_cloudfront_managed_prefix" {
  type = bool
}

variable "cloudfront_managed_prefix_list_id" {
  type = string
}
