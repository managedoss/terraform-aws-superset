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
  type    = string
  default = "latest"
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

resource "random_id" "id" {
  byte_length = 5
}

locals {
  random_id = random_id.id.id
  name      = var.name == "" ? "superset-${local.random_id}" : var.name
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

variable "admin_config" {
  type = object({
    username = string
    password = optional(string, null)
    email    = optional(string, "foo@example.com")
  })
  default = {
    username = null
  }
}

variable "log_level" {
  default     = "ERROR"
  description = "Python logging level"
  validation {
    condition     = contains(["INFO", "DEBUG", "ERROR", "WARN", "CRITICAL"], var.log_level)
    error_message = "log_level should be one of ${join(", ", ["INFO", "DEBUG", "ERROR", "WARN", "CRITICAL"])}"
  }
}
