resource "aws_cloudwatch_log_group" "superset" {
  name              = "/ecs/${local.name}"
  retention_in_days = 30
}
