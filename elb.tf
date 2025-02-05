data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  filter {
    name   = "tag:Name"
    values = ["vpc-365-scores-public-*"]  # Assumes your public subnets are tagged with "public-*"
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

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.web_elb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
