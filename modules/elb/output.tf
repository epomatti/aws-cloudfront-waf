output "auth_header" {
  value = random_string.auth_header.result
}

output "dns_name" {
  value = aws_lb.main.dns_name
}
