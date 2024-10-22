resource "random_string" "auth_header" {
  length  = 32
  special = false
  upper   = true
}

resource "aws_lb_target_group" "main" {
  name     = "tg-balancer"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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
  subnets            = var.subnets
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    target_group_arn = aws_lb_target_group.main.arn

    fixed_response {
      status_code  = 503
      content_type = "text/plain"
      message_body = "Default error reponse. The request did not match any rules."
    }
  }
}

resource "aws_lb_listener_rule" "forward" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 1

  action {
    type             = "fixed-response"
    target_group_arn = aws_lb_target_group.main.arn

    fixed_response {
      status_code  = 200
      content_type = "text/plain"
      message_body = "Verified the CloudFront authentication header."
    }
  }

  condition {
    http_header {
      http_header_name = "X-CloudFront-Auth"
      values           = [random_string.auth_header.result]
    }
  }

  tags = {
    "Name" = "CloudFront"
  }

  tags_all = {
    "Name" = "CloudFront"
  }
}

resource "aws_security_group" "allow_http_lb" {
  name        = "Allow HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

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
