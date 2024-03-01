module "superset" {
  source = "../"

  vpc_id         = "vpc-02e8793f8723abd03"
  alb_subnet_ids = ["subnet-026f47fe8065fbc83", "subnet-0a41bdca14917cdcc", "subnet-087c22f88ff4a8db1"]
  app_subnet_ids = ["subnet-026f47fe8065fbc83", "subnet-0a41bdca14917cdcc", "subnet-087c22f88ff4a8db1"]
  db_subnet_ids  = ["subnet-026f47fe8065fbc83", "subnet-0a41bdca14917cdcc", "subnet-087c22f88ff4a8db1"]

  assign_public_ip = true

  route53_zone   = "aws.managedoss.io"
  route53_domain = "superset"

  acm_certificate_arn = "arn:aws:acm:us-east-1:590183739501:certificate/a975e5f0-189c-4b60-be58-1c0e68084380"

  image_version = "v0.1.37-rc10"

  allow_self_register = true
  auth0_config = {
    client_id     = "/superset-example/auth0/client_id"
    client_secret = "/superset-example/auth0/client_secret"
    domain        = "/superset-example/auth0/domain"
  }

  log_level = "ERROR"

  # disable deletion protection for example
  deletion_protection = false

  database_config = {
    instance_count      = 1
    skip_final_snapshot = true
  }
}

provider "aws" {
  profile = "admin"
  region  = "us-east-1"
}
