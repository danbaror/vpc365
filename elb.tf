data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["${var.vpc_name}-public-*"]
  }
}

data "aws_subnet" "list" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_security_group" "elb_sg" {
  filter {
    name   = "tag:Name"
    values = ["elb-custom-sg"]
  }
}

data "aws_instance" "bastion" {
    filter {
    name   = "tag:Name"
    values = ["bastion1"]
  }
}
  
resource "aws_lb" "web_elb" {
  name               = var.elb_name
  internal           = false   # "false" makes it internet-facing
  load_balancer_type = "application"
  security_groups    = [data.aws_security_group.elb_sg.id]
  subnets            =  data.aws_subnets.public.ids  # Attach to public subnets

  tags = {
    Name = var.elb_name
    Type = "Application"
  }
}

resource "aws_lb_target_group" "web_tg_https" {
  name        = "web-target-group-https"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.existing.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTPS"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-tg-https"
  }
}

resource "aws_lb_target_group" "web_tg" {
  name        = "web-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.existing.id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-target-group"
  }
}

resource "aws_lb_target_group_attachment" "web_tg_attachment" {
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = data.aws_instance.bastion.id  # The EC2 instance ID
  port             = 80
}

resource "aws_lb_target_group_attachment" "web_tg_https_attachment" {
  target_group_arn = aws_lb_target_group.web_tg_https.arn
  target_id        = data.aws_instance.bastion.id  # The EC2 instance ID
  port            = 443
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

resource "aws_acm_certificate" "web_cert" {
  domain_name       = var.web_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "web-cert"
    Project = "VPC 365 Scores"
    Created = "06-Feb-2025"
  }
  depends_on = [aws_route53_record.elb_cname]
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.web_cert.arn  # Reference to ACM certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg_https.arn
  }
  depends_on = [aws_acm_certificate.web_cert]
}

# Retrieve the existing Route 53 hosted zone
data "aws_route53_zone" "dan_zone" {
  name         = var.domain_name
  private_zone = false
}

# Create a Route 53 record to point to the ALB
resource "aws_route53_record" "elb_cname" {
  zone_id = data.aws_route53_zone.dan_zone.zone_id
  name    = var.web_domain_name  # Subdomain pointing to the ELB
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.web_elb.dns_name]  # Use the ELB DNS name
}

