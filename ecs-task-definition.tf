locals {
  task_env = concat([
    {
      "name" : "LOG_LEVEL",
      "value" : var.log_level
    }
    ], [
    for k, v in var.feature_flags : {
      "name" : "FEATURE_FLAG_${k}",
      "value" : "True"
    } if v == true
    ],
    [
      for k, v in var.beta_feature_flags : {
        "name" : "BETA_FEATURE_FLAG_${k}",
        "value" : "True"
      } if v == true
  ])

  task_secrets = [for k, v in local.secrets :
    {
      "valueFrom" : "${aws_ssm_parameter.secrets[k].arn}",
      "name" : v.container_key
    }
  ]

  container_tasks = {
    server = {
      portMappings = [
        {
          containerPort = 8088
          hostPort      = 8088
        }
      ]
    }
    worker = {}
    beat   = {}
  }
}

data "aws_iam_policy_document" "superset_task_policy" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/*"]
    effect    = "Allow"
  }
}

data "aws_iam_policy_document" "superset_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "superset_task" {
  name               = "${local.name}-container-task"
  assume_role_policy = data.aws_iam_policy_document.superset_task_trust.json
  inline_policy {
    name   = "task_execution_policy"
    policy = data.aws_iam_policy_document.superset_task_policy.json
  }
}

resource "aws_ecs_task_definition" "superset" {
  family = local.name

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 2048
  memory                   = 4096

  execution_role_arn = aws_iam_role.superset_task.arn

  container_definitions = jsonencode([
    for task_name, task in local.container_tasks : {
      name         = task_name
      image        = "709825985650.dkr.ecr.us-east-1.amazonaws.com/managed-oss/superset:${var.image_version}"
      cpu          = 512
      memory       = 1024
      essential    = true
      portMappings = try(task.portMappings, [])
      command      = [task_name]
      secrets      = local.task_secrets
      environment  = local.task_env
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${local.name}"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-create-group"  = "true"
          "awslogs-stream-prefix" = task_name
        }
      }
    }
  ])
}
