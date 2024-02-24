locals {
  secrets = merge(
    {
      secret_key = {
        value         = random_password.secret_key.result
        container_key = "SUPERSET_SECRET_KEY"
      }
    },
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

