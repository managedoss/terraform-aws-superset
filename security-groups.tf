resource "aws_security_group" "superset_internet_to_alb" {
  name = "${local.name}-internet-to-alb"
}

resource "aws_security_group_rule" "allow_http_redirect" {
  security_group_id = aws_security_group.superset_internet_to_alb.id
  from_port         = "80"
  to_port           = "80"
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.allow_traffic_from
}

resource "aws_security_group_rule" "allow_ingest" {
  security_group_id = aws_security_group.superset_internet_to_alb.id
  from_port         = "443"
  to_port           = "443"
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = var.allow_traffic_from
}

resource "aws_security_group" "to_container" {
  name = "${local.name}-self"
}

resource "aws_security_group_rule" "to_container" {
  security_group_id = aws_security_group.to_container.id
  from_port         = "8088"
  to_port           = "8088"
  type              = "ingress"
  protocol          = "tcp"
  self              = true
}

resource "aws_security_group_rule" "to_container_out" {
  security_group_id = aws_security_group.to_container.id
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}
