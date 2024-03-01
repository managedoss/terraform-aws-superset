variable "name" {
  default     = ""
  description = "If you would like to customize the naming convention of your Superset instance"
}

variable "create_database" {
  type    = bool
  default = true
}

variable "use_serverless_aurora" {
  type    = bool
  default = true
}

variable "vpc_id" {
  type        = string
  description = "What VPC should all your infrastructure be configured in?"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "What subnets should the database be configured to run in? In some network topologies, databases are segmented in a separate, private network. These subnets should be within the same network as the VPC ID that you define."
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "What subnets should Superset run in? In some network topologies, applications live in a separate, private network.  These subnets should be within the same network as the VPC ID that you define."
}

variable "alb_subnet_ids" {
  type        = list(string)
  description = "What subnet should the ALB be configured to run in? In some network topologies, a specific network is configured to be exposed to the internet.  These subnets should be within the same network as the VPC ID that you define."
}

variable "allow_traffic_from" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Where should traffic be allowed from? If you require a VPN to connect to this service, specify the CIDR of your VPN. If you want to access this from anywhere, leave the CIDR as 0.0.0.0/0"
  validation {
    condition     = can([for cidr in var.allow_traffic_from : cidrhost(cidr, 32)])
    error_message = "Ensure all inputs are valid CIDRs."
  }
}

variable "image_version" {
  type = string
}

variable "assign_public_ip" {
  type        = bool
  default     = false
  description = "(Not Recommended) Assign public IPs to your containers if all networks are public (i.e., using default AWS VPC)"
}

variable "acm_certificate_arn" {
  type        = string
  description = "What certificate ARN should we use for your load balancer? It should be valid for the domain you are mapping to your service."
}

variable "route53_zone" {
  type        = string
  description = "Zone to create the record for accessing your service."
}

variable "route53_domain" {
  type        = string
  description = "Domain to assign to your load balancer and to create records for in Route53."
}

resource "random_string" "id" {
  length  = 5
  special = false
  lower   = true
}

locals {
  name = var.name == "" ? "superset-${random_string.id.result}" : var.name
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

variable "log_level" {
  default     = "ERROR"
  description = "Python logging level"
  validation {
    condition     = contains(["INFO", "DEBUG", "ERROR", "WARN", "CRITICAL"], var.log_level)
    error_message = "log_level should be one of ${join(", ", ["INFO", "DEBUG", "ERROR", "WARN", "CRITICAL"])}"
  }
}

variable "feature_flags" {
  type = object({
    ALERTS_ATTACH_REPORTS            = optional(bool, false)
    ALLOW_ADHOC_SUBQUERY             = optional(bool, false)
    DASHBOARD_CROSS_FILTERS          = optional(bool, false)
    DASHBOARD_RBAC                   = optional(bool, false)
    DATAPANEL_CLOSED_BY_DEFAULT      = optional(bool, false)
    DISABLE_LEGACY_DATASOURCE_EDITOR = optional(bool, false)
    DRUID_JOINS                      = optional(bool, false)
    EMBEDDABLE_CHARTS                = optional(bool, false)
    EMBEDDED_SUPERSET                = optional(bool, false)
    ENABLE_TEMPLATE_PROCESSING       = optional(bool, false)
    ESCAPE_MARKDOWN_HTML             = optional(bool, false)
    LISTVIEWS_DEFAULT_CARD_VIEW      = optional(bool, false)
    SCHEDULED_QUERIES                = optional(bool, false)
    SQLLAB_BACKEND_PERSISTENCE       = optional(bool, false)
    SQL_VALIDATORS_BY_ENGINE         = optional(bool, false)
    THUMBNAILS                       = optional(bool, false)
    ALERT_REPORTS                    = optional(bool, false)
    ALLOW_FULL_CSV_EXPORT            = optional(bool, false)
  })
  default = {}
}

variable "beta_feature_flags" {
  type = object({
    ALERT_REPORTS                     = optional(bool, false)
    ALLOW_FULL_CSV_EXPORT             = optional(bool, false)
    CACHE_IMPERSONATION               = optional(bool, false)
    CONFIRM_DASHBOARD_DIFF            = optional(bool, false)
    DASHBOARD_VIRTUALIZATION          = optional(bool, false)
    DRILL_BY                          = optional(bool, false)
    DRILL_TO_DETAIL                   = optional(bool, false)
    DYNAMIC_PLUGINS                   = optional(bool, false)
    ENABLE_JAVASCRIPT_CONTROLS        = optional(bool, false)
    ESTIMATE_QUERY_COST               = optional(bool, false)
    GENERIC_CHART_AXES                = optional(bool, false)
    GLOBAL_ASYNC_QUERIE               = optional(bool, false)
    HORIZONTAL_FILTER_BAR             = optional(bool, false)
    PLAYWRIGHT_REPORTS_AND_THUMBNAILS = optional(bool, false)
    RLS_IN_SQLLAB                     = optional(bool, false)
    SSH_TUNNELING                     = optional(bool, false)
    USE_ANALAGOUS_COLORS              = optional(bool, false)
  })
  default = {}
}

variable "auth0_config" {
  type = object({
    client_id     = string
    client_secret = string
    domain        = string
  })
  default = {
    client_id     = null
    client_secret = null
    domain        = null
  }
  description = "If using Auth0 for authenticating your users, define those values here. *All values should be the paths to values SSM Parameter Store.*"
}

variable "okta_config" {
  type = object({
    domain        = string
    client_id     = string
    client_secret = string
  })
  default = {
    client_id     = null
    client_secret = null
    domain        = null
  }
  description = "If using Okta for authenticating your users, define those values here. *All values should be the paths to values in SSM Parameter Store.*"
}

variable "azure_config" {
  type = object({
    tenant_id          = string
    application_id     = string
    application_secret = string
  })
  default = {
    tenant_id          = null
    application_id     = null
    application_secret = null
  }
  description = "If using an Azure App for authenticating your users, define those values here. *All values should be the paths to values SSM Parameter Store.*"
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "database_config" {
  type = object({
    create_db                = optional(bool, true)
    schema                   = optional(string, "superset")
    engine                   = optional(string, "aurora-mysql")
    engine_version           = optional(string, "8.0.mysql_aurora.3.02.0")
    instance_size            = optional(string, "db.t3.medium")
    user                     = optional(string, "superset")
    backup_rentention_period = optional(number, 3)
    port                     = optional(number, 3306)
    backup_window            = optional(string, "07:00-09:00")
    parameter_group          = optional(string, "default.aurora-mysql8.0")
    instance_count           = optional(number, 1)
    security_group           = optional(string, null)
    host                     = optional(string, null)
    skip_final_snapshot      = optional(bool, false)
    secrets = optional(object({
      password = optional(string, null)
    }), null)
  })
  default = {
    schema    = "superset"
    create_db = true
  }
  description = <<-EOT
  If `create_db` is disabled, you'll have to manage the database for Superset.

  If you leave `create_db` enabled, the module will create the RDS cluster for you. The created RDS cluster will default to using serverless instances.
  EOT
}

variable "local_admin" {
  type = object({
    username = string
    password = string
    email    = optional(string, "foo@example.com")
  })
  default = {
    username = null
    password = null
  }
  description = "(NOT RECOMMENDED) If using local users for authenticating your users, you must define a local admin account to initially login to. *All values should be the paths to values SSM Parameter Store.*"
}

variable "registration_role" {
  type        = string
  default     = "Admin"
  description = "Defines how automatically provisioned (via OAUTH) users are assigned by default to roles."
}

variable "allow_self_register" {
  type        = bool
  default     = false
  description = "Allows users to register themselves."
}
