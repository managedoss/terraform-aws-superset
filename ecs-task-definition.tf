locals {
  task_env = concat([
    {
      "name" : "SUPERSET_S3_CACHE_BUCKET",
      "value" : aws_s3_bucket.cache.bucket
    },
    {
      "name" : "SUPERSET_SQS_QUEUE_URL",
      "value" : aws_sqs_queue.queries.url
    },
    {
      "name" : "LOG_LEVEL",
      "value" : var.log_level
    },
    {
      "name" : "SUPERSET_DATABASE_HOST",
      "value" : coalesce(var.database_config.host, aws_rds_cluster.superset[0].endpoint)
    },
    {
      "name" : "SUPERSET_DATABASE_SCHEMA",
      "value" : var.database_config.schema
    },
    {
      "name" : "SUPERSET_DATABASE_PORT",
      "value" : tostring(var.database_config.port)
    },
    {
      "name" : "SUPERSET_DATABASE_USERNAME",
      "value" : tostring(var.database_config.user)
    },
    {
      "name" : "SUPERSET_DATABASE_ENGINE",
      "value" : strcontains(var.database_config.engine, "mysql") ? "mysql" : "postgres"
    },
    {
      "name" : "SUPERSET_AUTH_METHOD",
      "value" : var.auth0_config.client_id == null && var.azure_config.tenant_id == null && var.okta_config.client_id == null ? "LOCAL" : "OAUTH"
    },
    {
      "name" : "SUPERSET_ALLOW_USER_REGISTER",
      "value" : tostring(var.allow_self_register)
    },
    {
      "name" : "SUPERSET_USER_REGISTER_ROLE",
      "value" : var.registration_role
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
    [{
      "valueFrom" : length(data.aws_ssm_parameter.db_pass) > 0 ? var.database_config.secrets.password : "/${local.name}/db_master_pass",
      "name" : "SUPERSET_DATABASE_PASSWORD"
      }
    ]
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
    actions   = ["s3:Get*", "s3:Put*", "s3:Delete*", "s3:List*"]
    resources = [aws_s3_bucket.cache.arn, "${aws_s3_bucket.cache.arn}/*"]
    effect    = "Allow"
  }

  statement {
    actions   = ["sqs:Send*", "sqs:Receive*", "sqs:getqueueattributes", "sqs:DeleteMessageBatch"]
    resources = [aws_sqs_queue.queries.arn]
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

  task_role_arn = aws_iam_role.superset_task.arn
  # TODO: create a separate iam role to pull ssm values
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
