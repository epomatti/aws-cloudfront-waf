output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
}
