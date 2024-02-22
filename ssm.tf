locals {
  secrets = merge(
    {
      secret_key = {
        value         = random_password.secret_key.result
        container_key = "SUPERSET_SECRET_KEY"
      }
    },
    var.admin_config["username"] != null ? {
      default_admin = {
        value = jsonencode({
          username = var.admin_config["username"]
          password = var.admin_config["password"] != null ? var.admin_config["password"] : random_password.admin_password.result
          email    = var.admin_config["email"]
        })
        container_key = "SUPERSET_ADMIN_CONFIG"
      }
    } : {}
  )
}

resource "aws_ssm_parameter" "secrets" {
  for_each = local.secrets

  name  = "/${local.name}/${each.key}"
  value = each.value["value"]
  type  = "SecureString"
}

resource "random_password" "secret_key" {
  length  = 16
  special = false
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}
