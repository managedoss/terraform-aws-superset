resource "aws_ecs_cluster" "superset" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
