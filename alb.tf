resource "aws_lb" "superset" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.superset_internet_to_alb.id, aws_security_group.to_container.id]
  subnets            = var.alb_subnet_ids

  enable_deletion_protection = var.deletion_protection
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.superset.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.superset.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.superset.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "superset" {
  name = local.name

  vpc_id      = var.vpc_id
  port        = 8088
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path     = "/login/"
    port     = "8088"
    interval = 30
  }
}
