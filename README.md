## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.37.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.superset_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lb.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.superset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.superset_internet_to_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.to_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.allow_http_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.allow_ingest](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.to_container](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.to_container_out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_password.admin_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.secret_key](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.superset_task_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.superset_task_trust](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | What certificate ARN should we use for your load balancer? It should be valid for the domain you are mapping to your service. | `string` | n/a | yes |
| <a name="input_alb_subnet_ids"></a> [alb\_subnet\_ids](#input\_alb\_subnet\_ids) | What subnet should the ALB be configured to run in? In some network topologies, a specific network is configured to be exposed to the internet.  These subnets should be within the same network as the VPC ID that you define. | `list(string)` | n/a | yes |
| <a name="input_allow_self_register"></a> [allow\_self\_register](#input\_allow\_self\_register) | Allows users to register themselves. | `bool` | `false` | no |
| <a name="input_allow_traffic_from"></a> [allow\_traffic\_from](#input\_allow\_traffic\_from) | Where should traffic be allowed from? If you require a VPN to connect to this service, specify the CIDR of your VPN. If you want to access this from anywhere, leave the CIDR as 0.0.0.0/0 | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_app_subnet_ids"></a> [app\_subnet\_ids](#input\_app\_subnet\_ids) | What subnets should Superset run in? In some network topologies, applications live in a separate, private network.  These subnets should be within the same network as the VPC ID that you define. | `list(string)` | n/a | yes |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | (Not Recommended) Assign public IPs to your containers if all networks are public (i.e., using default AWS VPC) | `bool` | `false` | no |
| <a name="input_auth0_config"></a> [auth0\_config](#input\_auth0\_config) | If using Auth0 for authenticating your users, define those values here. *All values should be the paths to values SSM Parameter Store.* | <pre>object({<br>    client_id     = string<br>    client_secret = string<br>    domain        = string<br>  })</pre> | `{}` | no |
| <a name="input_auth_method"></a> [auth\_method](#input\_auth\_method) | Supported authentication methods include LOCAL or OAUTH | `string` | `"LOCAL"` | no |
| <a name="input_azure_auth"></a> [azure\_auth](#input\_azure\_auth) | If using an Azure App for authenticating your users, define those values here. *All values should be the paths to values SSM Parameter Store.* | <pre>object({<br>    tenant_id          = string<br>    application_id     = string<br>    application_secret = string<br>  })</pre> | `{}` | no |
| <a name="input_beta_feature_flags"></a> [beta\_feature\_flags](#input\_beta\_feature\_flags) | n/a | <pre>object({<br>    ALERT_REPORTS                     = optional(bool, false)<br>    ALLOW_FULL_CSV_EXPORT             = optional(bool, false)<br>    CACHE_IMPERSONATION               = optional(bool, false)<br>    CONFIRM_DASHBOARD_DIFF            = optional(bool, false)<br>    DASHBOARD_VIRTUALIZATION          = optional(bool, false)<br>    DRILL_BY                          = optional(bool, false)<br>    DRILL_TO_DETAIL                   = optional(bool, false)<br>    DYNAMIC_PLUGINS                   = optional(bool, false)<br>    ENABLE_JAVASCRIPT_CONTROLS        = optional(bool, false)<br>    ESTIMATE_QUERY_COST               = optional(bool, false)<br>    GENERIC_CHART_AXES                = optional(bool, false)<br>    GLOBAL_ASYNC_QUERIE               = optional(bool, false)<br>    HORIZONTAL_FILTER_BAR             = optional(bool, false)<br>    PLAYWRIGHT_REPORTS_AND_THUMBNAILS = optional(bool, false)<br>    RLS_IN_SQLLAB                     = optional(bool, false)<br>    SSH_TUNNELING                     = optional(bool, false)<br>    USE_ANALAGOUS_COLORS              = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_create_database"></a> [create\_database](#input\_create\_database) | n/a | `bool` | `true` | no |
| <a name="input_db_subnet_ids"></a> [db\_subnet\_ids](#input\_db\_subnet\_ids) | What subnets should the database be configured to run in? In some network topologies, databases are segmented in a separate, private network. These subnets should be within the same network as the VPC ID that you define. | `list(string)` | n/a | yes |
| <a name="input_feature_flags"></a> [feature\_flags](#input\_feature\_flags) | n/a | <pre>object({<br>    ALERTS_ATTACH_REPORTS            = optional(bool, false)<br>    ALLOW_ADHOC_SUBQUERY             = optional(bool, false)<br>    DASHBOARD_CROSS_FILTERS          = optional(bool, false)<br>    DASHBOARD_RBAC                   = optional(bool, false)<br>    DATAPANEL_CLOSED_BY_DEFAULT      = optional(bool, false)<br>    DISABLE_LEGACY_DATASOURCE_EDITOR = optional(bool, false)<br>    DRUID_JOINS                      = optional(bool, false)<br>    EMBEDDABLE_CHARTS                = optional(bool, false)<br>    EMBEDDED_SUPERSET                = optional(bool, false)<br>    ENABLE_TEMPLATE_PROCESSING       = optional(bool, false)<br>    ESCAPE_MARKDOWN_HTML             = optional(bool, false)<br>    LISTVIEWS_DEFAULT_CARD_VIEW      = optional(bool, false)<br>    SCHEDULED_QUERIES                = optional(bool, false)<br>    SQLLAB_BACKEND_PERSISTENCE       = optional(bool, false)<br>    SQL_VALIDATORS_BY_ENGINE         = optional(bool, false)<br>    THUMBNAILS                       = optional(bool, false)<br>    ALERT_REPORTS                    = optional(bool, false)<br>    ALLOW_FULL_CSV_EXPORT            = optional(bool, false)<br>  })</pre> | `{}` | no |
| <a name="input_image_version"></a> [image\_version](#input\_image\_version) | n/a | `string` | `"latest"` | no |
| <a name="input_local_admin"></a> [local\_admin](#input\_local\_admin) | (NOT RECOMMENDED) If using local users for authenticating your users, you must define a local admin account to initially login to. *All values should be the paths to values SSM Parameter Store.* | <pre>object({<br>    username = string<br>    password = string<br>    email    = optional(string, "foo@example.com")<br>  })</pre> | `{}` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Python logging level | `string` | `"ERROR"` | no |
| <a name="input_name"></a> [name](#input\_name) | If you would like to customize the naming convention of your Superset instance | `string` | `""` | no |
| <a name="input_okta_config"></a> [okta\_config](#input\_okta\_config) | If using Okta for authenticating your users, define those values here. *All values should be the paths to values in SSM Parameter Store.* | <pre>object({<br>    domain        = string<br>    client_id     = string<br>    client_secret = string<br>  })</pre> | `{}` | no |
| <a name="input_registration_role"></a> [registration\_role](#input\_registration\_role) | Defines how automatically provisioned (via OAUTH) users are assigned by default to roles. | `string` | `"Admin"` | no |
| <a name="input_route53_domain"></a> [route53\_domain](#input\_route53\_domain) | Domain to assign to your load balancer and to create records for in Route53. | `string` | n/a | yes |
| <a name="input_route53_zone"></a> [route53\_zone](#input\_route53\_zone) | Zone to create the record for accessing your service. | `string` | n/a | yes |
| <a name="input_use_serverless_aurora"></a> [use\_serverless\_aurora](#input\_use\_serverless\_aurora) | n/a | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | What VPC should all your infrastructure be configured in? | `string` | n/a | yes |

## Outputs

No outputs.
