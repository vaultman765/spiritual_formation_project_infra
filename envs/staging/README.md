# Spiritual Formation
<!-- BEGIN_TF_DOCS -->
#### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.55 |

#### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

#### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_apprunner"></a> [apprunner](#module\_apprunner) | ../../modules/apprunner | n/a |
| <a name="module_ci_frontend_role_staging"></a> [ci\_frontend\_role\_staging](#module\_ci\_frontend\_role\_staging) | ../../modules/github_oidc_deploy_role | n/a |
| <a name="module_client_vpn"></a> [client\_vpn](#module\_client\_vpn) | ../../modules/client_vpn | n/a |
| <a name="module_ecr_backend"></a> [ecr\_backend](#module\_ecr\_backend) | ../../modules/ecr | n/a |
| <a name="module_ecs_import"></a> [ecs\_import](#module\_ecs\_import) | ../../modules/ecs_import_job | n/a |
| <a name="module_frontend_staging"></a> [frontend\_staging](#module\_frontend\_staging) | ../../modules/cloudfront_site | n/a |
| <a name="module_github_oidc_apprepo_build"></a> [github\_oidc\_apprepo\_build](#module\_github\_oidc\_apprepo\_build) | ../../modules/iam/github_oidc_role | n/a |
| <a name="module_github_oidc_apprepo_metadata"></a> [github\_oidc\_apprepo\_metadata](#module\_github\_oidc\_apprepo\_metadata) | ../../modules/iam/github_oidc_role | n/a |
| <a name="module_github_oidc_infra"></a> [github\_oidc\_infra](#module\_github\_oidc\_infra) | ../../modules/iam/github_oidc | n/a |
| <a name="module_rds"></a> [rds](#module\_rds) | ../../modules/rds | n/a |
| <a name="module_redirect_mwc"></a> [redirect\_mwc](#module\_redirect\_mwc) | ../../modules/redirect_domain | n/a |
| <a name="module_route53_acm_api_staging"></a> [route53\_acm\_api\_staging](#module\_route53\_acm\_api\_staging) | ../../modules/route53_acm | n/a |
| <a name="module_route53_acm_frontend_staging"></a> [route53\_acm\_frontend\_staging](#module\_route53\_acm\_frontend\_staging) | ../../modules/route53_acm | n/a |
| <a name="module_route53_acm_static_staging"></a> [route53\_acm\_static\_staging](#module\_route53\_acm\_static\_staging) | ../../modules/route53_acm | n/a |
| <a name="module_s3"></a> [s3](#module\_s3) | ../../modules/s3 | n/a |
| <a name="module_static_admin_staging"></a> [static\_admin\_staging](#module\_static\_admin\_staging) | ../../modules/cloudfront_static | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |

#### Resources

| Name | Type |
|------|------|
| [aws_apprunner_custom_domain_association.api_staging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apprunner_custom_domain_association) | resource |
| [aws_cloudwatch_event_rule.s3_metadata_object_created](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.run_import_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.app_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.events_to_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.exec_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.metadata_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.events_to_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.app_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.events_to_ecs_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.exec_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.metadata_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_route53_record.apprunner_api_cname](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.apprunner_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.apprunner_connector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.ecs_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.vpce](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ecs_tasks_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.vpce_ingress_from_tasks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.secretsmanager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_ecr_repository.backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_repository) | data source |
| [aws_iam_policy_document.app_build](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.events_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.events_to_ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.metadata_sync](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.import_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_iam_role.import_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_route53_zone.catholic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

#### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage_gb"></a> [allocated\_storage\_gb](#input\_allocated\_storage\_gb) | Allocated storage in GB. | `number` | n/a | yes |
| <a name="input_allowed_hosts"></a> [allowed\_hosts](#input\_allowed\_hosts) | Comma-separated list of allowed hosts. | `string` | n/a | yes |
| <a name="input_api_domain_name"></a> [api\_domain\_name](#input\_api\_domain\_name) | API domain name. | `string` | n/a | yes |
| <a name="input_apprunner_auto_deployments"></a> [apprunner\_auto\_deployments](#input\_apprunner\_auto\_deployments) | Enable AppRunner auto-deployments on new ECR image. | `bool` | n/a | yes |
| <a name="input_apprunner_cpu"></a> [apprunner\_cpu](#input\_apprunner\_cpu) | App Runner CPU units. | `number` | n/a | yes |
| <a name="input_apprunner_image_tag"></a> [apprunner\_image\_tag](#input\_apprunner\_image\_tag) | App Runner image tag. | `string` | n/a | yes |
| <a name="input_apprunner_memory"></a> [apprunner\_memory](#input\_apprunner\_memory) | App Runner memory in MB. | `number` | n/a | yes |
| <a name="input_apprunner_service_arn"></a> [apprunner\_service\_arn](#input\_apprunner\_service\_arn) | Exact App Runner service ARN (preferred when available). | `string` | `""` | no |
| <a name="input_apprunner_service_name"></a> [apprunner\_service\_name](#input\_apprunner\_service\_name) | AppRunner Service Name. | `string` | `"sf-staging-apprunner-svc"` | no |
| <a name="input_aws_acct_num"></a> [aws\_acct\_num](#input\_aws\_acct\_num) | AWS account number. | `string` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | VPC CIDR block. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_client_vpn_server_cert_arn"></a> [client\_vpn\_server\_cert\_arn](#input\_client\_vpn\_server\_cert\_arn) | ARN for the VPN server certificate. | `string` | `"arn:aws:acm:us-east-1:756859458263:certificate/7c7c3042-872b-499d-9ec4-b47f3f711db4"` | no |
| <a name="input_cors_allowed_origins"></a> [cors\_allowed\_origins](#input\_cors\_allowed\_origins) | Comma-separated list of CORS allowed origins. | `string` | n/a | yes |
| <a name="input_csrf_trusted_origins"></a> [csrf\_trusted\_origins](#input\_csrf\_trusted\_origins) | Comma-separated list of CSRF trusted origins. | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name. | `string` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Database username. | `string` | n/a | yes |
| <a name="input_django_secret_arn"></a> [django\_secret\_arn](#input\_django\_secret\_arn) | Secrets Manager ARN for Django secret key. | `string` | n/a | yes |
| <a name="input_ecr_repo_name"></a> [ecr\_repo\_name](#input\_ecr\_repo\_name) | ECR repository name to push/pull. | `string` | `"spiritual-formation-backend"` | no |
| <a name="input_enable_apprunner_permissions"></a> [enable\_apprunner\_permissions](#input\_enable\_apprunner\_permissions) | If false, do not include App Runner permissions (for cost-savings mode). | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | Deployment environment (e.g., staging, prod). | `string` | n/a | yes |
| <a name="input_frontend_domain_name"></a> [frontend\_domain\_name](#input\_frontend\_domain\_name) | Frontend domain name. | `string` | n/a | yes |
| <a name="input_github_owner"></a> [github\_owner](#input\_github\_owner) | GitHub organization/owner. | `string` | n/a | yes |
| <a name="input_github_refs"></a> [github\_refs](#input\_github\_refs) | GitHub refs for OIDC trust. | `list(string)` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | GitHub repository name. | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | RDS instance class. | `string` | n/a | yes |
| <a name="input_max_allocated_storage_gb"></a> [max\_allocated\_storage\_gb](#input\_max\_allocated\_storage\_gb) | Max allocated storage in GB. | `number` | n/a | yes |
| <a name="input_metadata_bucket"></a> [metadata\_bucket](#input\_metadata\_bucket) | Name of the metadata S3 bucket. | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Enable Multi-AZ for RDS. | `bool` | n/a | yes |
| <a name="input_mwc_sources"></a> [mwc\_sources](#input\_mwc\_sources) | Sources for the meditationwithchrist redirect. | `list(string)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Stable name prefix for staging resources (e.g., sf-staging). | `string` | `"sf-staging"` | no |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | NAT gateway mode: single \| per\_az \| none. | `string` | `"single"` | no |
| <a name="input_private_subnet_cidrs"></a> [private\_subnet\_cidrs](#input\_private\_subnet\_cidrs) | Private subnet CIDRs. | `list(string)` | <pre>[<br/>  "10.0.10.0/24",<br/>  "10.0.11.0/24"<br/>]</pre> | no |
| <a name="input_project"></a> [project](#input\_project) | Project name. | `string` | n/a | yes |
| <a name="input_public_subnet_cidrs"></a> [public\_subnet\_cidrs](#input\_public\_subnet\_cidrs) | Public subnet CIDRs. | `list(string)` | <pre>[<br/>  "10.0.0.0/24",<br/>  "10.0.1.0/24"<br/>]</pre> | no |
| <a name="input_rds_secret_arn"></a> [rds\_secret\_arn](#input\_rds\_secret\_arn) | Secrets Manager ARN for RDS credentials. | `string` | n/a | yes |
| <a name="input_redirect_hosted_zone_id"></a> [redirect\_hosted\_zone\_id](#input\_redirect\_hosted\_zone\_id) | Hosted zone ID for the redirect domain. | `string` | n/a | yes |
| <a name="input_redirect_root_domain_name"></a> [redirect\_root\_domain\_name](#input\_redirect\_root\_domain\_name) | Root domain for redirect. | `string` | `"meditationwithchrist.com"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | n/a | yes |
| <a name="input_root_domain_name"></a> [root\_domain\_name](#input\_root\_domain\_name) | Root domain name. | `string` | `"catholicmentalprayer.com"` | no |
| <a name="input_s3_bucket_name"></a> [s3\_bucket\_name](#input\_s3\_bucket\_name) | General S3 bucket name. | `string` | `"spiritual-formation-staging"` | no |
| <a name="input_staging_infra_enabled"></a> [staging\_infra\_enabled](#input\_staging\_infra\_enabled) | Master switch for staging compute/network (VPC, RDS, App Runner). | `bool` | `true` | no |
| <a name="input_staging_low_cost"></a> [staging\_low\_cost](#input\_staging\_low\_cost) | Use low-cost mode (no NAT/interface endpoints; import task uses public subnets). | `bool` | `false` | no |
| <a name="input_staging_rds_from_latest_snapshot"></a> [staging\_rds\_from\_latest\_snapshot](#input\_staging\_rds\_from\_latest\_snapshot) | On enable, restore staging RDS from latest manual snapshot instead of creating fresh. | `bool` | `false` | no |
| <a name="input_static_admin_alias"></a> [static\_admin\_alias](#input\_static\_admin\_alias) | FQDN for admin static CloudFront host (e.g. static.staging.catholicmentalprayer.com). | `string` | `null` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain for environment. | `string` | n/a | yes |
| <a name="input_vpn_enabled"></a> [vpn\_enabled](#input\_vpn\_enabled) | Create the Client VPN when true; destroy/skip when false. | `bool` | `false` | no |

#### Outputs

| Name | Description |
|------|-------------|
| <a name="output_apex_zone_id"></a> [apex\_zone\_id](#output\_apex\_zone\_id) | Zone ID for catholicmentalprayer.com |
| <a name="output_apprepo_build_role_arn"></a> [apprepo\_build\_role\_arn](#output\_apprepo\_build\_role\_arn) | n/a |
| <a name="output_apprepo_metadata_role_arn"></a> [apprepo\_metadata\_role\_arn](#output\_apprepo\_metadata\_role\_arn) | n/a |
| <a name="output_apprunner_connector_sg_id"></a> [apprunner\_connector\_sg\_id](#output\_apprunner\_connector\_sg\_id) | n/a |
| <a name="output_apprunner_service_arn"></a> [apprunner\_service\_arn](#output\_apprunner\_service\_arn) | n/a |
| <a name="output_client_vpn_endpoint_id"></a> [client\_vpn\_endpoint\_id](#output\_client\_vpn\_endpoint\_id) | Client VPN endpoint ID (null when disabled) |
| <a name="output_client_vpn_sg_id"></a> [client\_vpn\_sg\_id](#output\_client\_vpn\_sg\_id) | Security group attached to the Client VPN ENI (null when disabled) |
| <a name="output_distribution_id"></a> [distribution\_id](#output\_distribution\_id) | CloudFront distribution ID for frontend. |
| <a name="output_ecr_backend_arn"></a> [ecr\_backend\_arn](#output\_ecr\_backend\_arn) | n/a |
| <a name="output_ecr_backend_url"></a> [ecr\_backend\_url](#output\_ecr\_backend\_url) | n/a |
| <a name="output_ecs_tasks_sg_id"></a> [ecs\_tasks\_sg\_id](#output\_ecs\_tasks\_sg\_id) | n/a |
| <a name="output_frontend_bucket"></a> [frontend\_bucket](#output\_frontend\_bucket) | n/a |
| <a name="output_frontend_ci_role_arn"></a> [frontend\_ci\_role\_arn](#output\_frontend\_ci\_role\_arn) | Use this ARN in GitHub Actions (AWS\_ROLE\_ARN\_STAGING). |
| <a name="output_github_infra_role_arn"></a> [github\_infra\_role\_arn](#output\_github\_infra\_role\_arn) | n/a |
| <a name="output_github_oidc_provider_arn"></a> [github\_oidc\_provider\_arn](#output\_github\_oidc\_provider\_arn) | n/a |
| <a name="output_metadata_bucket"></a> [metadata\_bucket](#output\_metadata\_bucket) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_rds_endpoint"></a> [rds\_endpoint](#output\_rds\_endpoint) | n/a |
| <a name="output_rds_secret"></a> [rds\_secret](#output\_rds\_secret) | n/a |
| <a name="output_staging_frontend_alias"></a> [staging\_frontend\_alias](#output\_staging\_frontend\_alias) | Route53 A/ALIAS record created for staging.catholicmentalprayer.com. |
| <a name="output_staging_frontend_bucket"></a> [staging\_frontend\_bucket](#output\_staging\_frontend\_bucket) | S3 bucket where you upload the built staging frontend. |
| <a name="output_staging_frontend_cf_domain"></a> [staging\_frontend\_cf\_domain](#output\_staging\_frontend\_cf\_domain) | CloudFront domain name for staging. |
| <a name="output_static_acm_arn"></a> [static\_acm\_arn](#output\_static\_acm\_arn) | ACM ARN for static.staging.catholicmentalprayer.com |
| <a name="output_static_admin_alias"></a> [static\_admin\_alias](#output\_static\_admin\_alias) | Route53 alias record for static admin host. |
| <a name="output_static_admin_cf_domain"></a> [static\_admin\_cf\_domain](#output\_static\_admin\_cf\_domain) | CloudFront domain for static admin host. |
| <a name="output_static_admin_distribution_id"></a> [static\_admin\_distribution\_id](#output\_static\_admin\_distribution\_id) | CloudFront distribution ID for static admin host. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->    