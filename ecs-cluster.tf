resource "aws_ecs_cluster" "superset" {
  name = local.name
}
