data "aws_subnet" "selected" {
  count = length(var.db_subnet_ids)
  id    = var.db_subnet_ids[count.index]
}

resource "aws_rds_cluster" "superset" {
  count = var.database_config.create_db == true ? 1 : 0

  cluster_identifier      = lower(local.name)
  engine                  = var.database_config.engine
  engine_version          = var.database_config.engine_version
  availability_zones      = [for subnet in data.aws_subnet.selected : subnet.availability_zone]
  database_name           = var.database_config.schema
  master_username         = var.database_config.user
  master_password         = length(data.aws_ssm_parameter.db_pass) > 0 ? data.aws_ssm_parameter.db_pass[0].value : random_password.db_pass[0].result
  port                    = var.database_config.port
  backup_retention_period = var.database_config.backup_rentention_period
  preferred_backup_window = var.database_config.backup_window
  deletion_protection     = var.deletion_protection
  vpc_security_group_ids  = [aws_security_group.rds.id]

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.database_config.instance_size == "db.serverless" ? [1] : []
    content {
      min_capacity = "0.5"
      max_capacity = "10"
    }
  }
}

data "aws_ssm_parameter" "db_pass" {
  count           = var.database_config.secrets != null ? var.database_config.secrets.password != null ? 1 : 0 : 0
  name            = var.database_config.secrets.password
  with_decryption = true
}

resource "aws_ssm_parameter" "db_pass" {
  count = length(data.aws_ssm_parameter.db_pass) > 0 ? 0 : 1
  name  = "/${local.name}/db_master_pass"
  type  = "SecureString"
  value = random_password.db_pass[0].result
}

resource "random_password" "db_pass" {
  count   = length(data.aws_ssm_parameter.db_pass) > 0 ? 0 : 1
  length  = 16
  special = false
}

resource "aws_rds_cluster_instance" "superset" {
  count               = var.database_config.create_db == true ? var.database_config.instance_count : 0
  cluster_identifier  = aws_rds_cluster.superset[0].id
  identifier          = "${lower(local.name)}-${count.index}"
  instance_class      = var.database_config.instance_size
  engine              = aws_rds_cluster.superset[0].engine
  engine_version      = aws_rds_cluster.superset[0].engine_version
  publicly_accessible = var.assign_public_ip
}
