data "aws_region" "current" {}

locals {
  aws_region = data.aws_region.current.name

  azs = ["${local.aws_region}a", "${local.aws_region}b"]
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "igw-lb-${var.project_name}"
  }
}

resource "aws_default_route_table" "internet" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "internet-rt-${var.project_name}"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "lb-${var.project_name}-subnet1"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "lb-${var.project_name}-subnet2"
  }
}
