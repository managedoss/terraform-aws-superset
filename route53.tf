data "aws_route53_zone" "zone" {
  name = var.route53_zone
}

resource "aws_route53_record" "superset" {
  zone_id = data.aws_route53_zone.zone.id
  name    = var.route53_domain
  type    = "A"
  alias {
    zone_id                = aws_lb.superset.zone_id
    name                   = aws_lb.superset.dns_name
    evaluate_target_health = true
  }
}
