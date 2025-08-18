## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.pg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_secretsmanager_secret.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.db_current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.all_out](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.from_sgs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [random_password.db](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_static.final](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_cidr_blocks"></a> [admin\_cidr\_blocks](#input\_admin\_cidr\_blocks) | n/a | `list(string)` | `[]` | no |
| <a name="input_allocated_storage_gb"></a> [allocated\_storage\_gb](#input\_allocated\_storage\_gb) | n/a | `number` | `20` | no |
| <a name="input_allowed_sg_ids"></a> [allowed\_sg\_ids](#input\_allowed\_sg\_ids) | Who may reach Postgres (we pass SG IDs from the env) | `map(string)` | `{}` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | n/a | `string` | `"spiritualformation"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | n/a | `string` | `"sf_admin"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Create RDS resources when true. | `bool` | `true` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | DB settings (cheap defaults for staging) | `string` | `"16.8"` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_final_snapshot_prefix"></a> [final\_snapshot\_prefix](#input\_final\_snapshot\_prefix) | Prefix used for the final snapshot name on destroy. | `string` | `"sf-staging-final"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | DB instance identifier (e.g., sf-staging-db). If empty, AWS auto-names and 'latest snapshot' lookup is disabled. | `string` | `""` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | n/a | `string` | `"db.t4g.micro"` | no |
| <a name="input_max_allocated_storage_gb"></a> [max\_allocated\_storage\_gb](#input\_max\_allocated\_storage\_gb) | n/a | `number` | `100` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | n/a | `bool` | `false` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `string` | n/a | yes |
| <a name="input_restore_from_latest_snapshot"></a> [restore\_from\_latest\_snapshot](#input\_restore\_from\_latest\_snapshot) | If true and an identifier is set, restore from the latest manual snapshot of that instance. | `bool` | `false` | no |
| <a name="input_restore_snapshot_identifier"></a> [restore\_snapshot\_identifier](#input\_restore\_snapshot\_identifier) | Explicit snapshot identifier to restore from (takes precedence over restore\_from\_latest\_snapshot). | `string` | `""` | no |
| <a name="input_secret_name"></a> [secret\_name](#input\_secret\_name) | Secrets Manager | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_endpoint"></a> [db\_endpoint](#output\_db\_endpoint) | n/a |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | n/a |
| <a name="output_db_port"></a> [db\_port](#output\_db\_port) | n/a |
| <a name="output_db_username"></a> [db\_username](#output\_db\_username) | n/a |
| <a name="output_rds_sg_id"></a> [rds\_sg\_id](#output\_rds\_sg\_id) | n/a |
| <a name="output_secret_arn"></a> [secret\_arn](#output\_secret\_arn) | n/a |
