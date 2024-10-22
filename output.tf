output "cloufront_domain_name" {
  value = module.cloudfront.domain_name
}

output "elb_dns_name" {
  value = module.elb.dns_name
}
