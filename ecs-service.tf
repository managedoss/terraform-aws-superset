resource "aws_ecs_service" "superset" {
  depends_on = [aws_lb_listener.https]
  name       = local.name

  cluster = aws_ecs_cluster.superset.name

  health_check_grace_period_seconds = 120
  launch_type                       = "FARGATE"
  task_definition                   = aws_ecs_task_definition.superset.arn
  desired_count                     = 1

  network_configuration {
    assign_public_ip = var.assign_public_ip
    security_groups  = [aws_security_group.to_container.id]
    subnets          = var.app_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.superset.arn
    container_name   = "server"
    container_port   = local.container_tasks.server.portMappings[0].containerPort
  }

  force_new_deployment = true

  triggers = {
    redeployment = plantimestamp()
  }
}
