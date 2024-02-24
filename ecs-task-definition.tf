locals {
  task_env = concat([
    {
      "name" : "SUPERSET_LOG_LEVEL",
      "value" : var.log_level
    },
    {
      "name" : "SUPERSET_AUTH_METHOD",
      "value" : var.auth0_config.client_id == null && var.azure_config.tenant_id == null && var.okta_config.client_id == null ? "LOCAL" : "OAUTH"
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

  task_secrets = concat(
    [
      for k, v in local.secrets :
      {
        "valueFrom" : "/${local.name}/secret_key",
        "name" : v.container_key
      }
    ],
    var.auth0_config.client_id == null ? [] : [
      {
        "valueFrom" : "${var.auth0_config.client_id}",
        "name" : "SUPERSET_OAUTH_AUTH0_CLIENT_ID"
      },
      {
        "valueFrom" : "${var.auth0_config.client_secret}",
        "name" : "SUPERSET_OAUTH_AUTH0_CLIENT_SECRET"
      },
      {
        "valueFrom" : "${var.auth0_config.domain}",
        "name" : "SUPERSET_OAUTH_AUTH0_DOMAIN"
      }
    ],
    var.azure_config.application_id == null ? [] : [
      {
        "valueFrom" : "${var.azure_config.tenant_id}",
        "name" : "SUPERSET_OAUTH_AZURE_TENANT_ID"
      },
      {
        "valueFrom" : "${var.azure_config.application_secret}",
        "name" : "SUPERSET_OAUTH_AZURE_APPLICATION_SECRET"
      },
      {
        "valueFrom" : "${var.azure_config.application_id}",
        "name" : "SUPERSET_OAUTH_AZURE_APPLICATION_ID"
      }
    ],
    var.okta_config.client_id == null ? [] : [
      {
        "valueFrom" : "${var.okta_config.client_id}",
        "name" : "SUPERSET_OAUTH_OKTA_CLIENT_ID"
      },
      {
        "valueFrom" : "${var.okta_config.client_secret}",
        "name" : "SUPERSET_OAUTH_OKTA_CLIENT_SECRET"
      },
      {
        "valueFrom" : "${var.okta_config.domain}",
        "name" : "SUPERSET_OAUTH_OKTA_DOMAIN"
      }
    ],
    var.local_admin.username == null ? [] : [
      {
        "valueFrom" : "${var.local_admin.username}",
        "name" : "SUPERSET_ADMIN_CONFIG_USERNAME"
      },
      {
        "valueFrom" : "${var.local_admin.password}",
        "name" : "SUPERSET_ADMIN_CONFIG_PASSWORD"
      },
      {
        "valueFrom" : "${var.local_admin.email}",
        "name" : "SUPERSET_ADMIN_CONFIG_EMAIL"
      }
    ],
  )

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
    resources = [for k, v in toset(local.task_secrets) : "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${v.valueFrom}"]
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
