# Terraform Refactor: State Migration Map (staging → modules)

This document tracks which resources need to be migrated from
inline `envs/staging` Terraform to reusable `modules/`.

## IAM (GitHub OIDC + CI policies) - ✅ Done

**From `app-roles.tf`, `exec-secrets.tf`, `task-secrets.tf`:**

- `aws_iam_policy.metadata_sync`
- `aws_iam_role_policy_attachment.metadata_sync`
- `aws_iam_policy.app_build`
- `aws_iam_role_policy_attachment.app_build`
- `aws_iam_policy.exec_read_secrets`
- `aws_iam_role_policy_attachment.exec_read_secrets`
- `aws_iam_policy.task_read_secrets`
- `aws_iam_role_policy_attachment.task_read_secrets`

**To → `module.ci_app_policies`**

```bash
terraform state mv aws_iam_policy.metadata_sync \
  module.ci_app_policies.aws_iam_policy.metadata_sync
terraform state mv aws_iam_role_policy_attachment.metadata_sync \
  module.ci_app_policies.aws_iam_role_policy_attachment.metadata_sync_attach

terraform state mv aws_iam_policy.app_build \
  module.ci_app_policies.aws_iam_policy.app_build
terraform state mv aws_iam_role_policy_attachment.app_build \
  module.ci_app_policies.aws_iam_role_policy_attachment.app_build_attach

terraform state mv aws_iam_policy.exec_read_secrets \
  module.ci_app_policies.aws_iam_policy.exec_read_secrets
terraform state mv aws_iam_role_policy_attachment.exec_read_secrets \
  module.ci_app_policies.aws_iam_role_policy_attachment.exec_read_secrets_attach

terraform state mv aws_iam_policy.task_read_secrets \
  module.ci_app_policies.aws_iam_policy.task_read_secrets
terraform state mv aws_iam_role_policy_attachment.task_read_secrets \
  module.ci_app_policies.aws_iam_role_policy_attachment.task_read_secrets_attach
```

## Redirects - ✅ Done

- Already migrated → module.redirect_domain
- ✅ No move needed.

## Route53 + ACM - ✅ Done

- Already migrated → module.route53_acm_*
- ✅ No move needed.

## EventBridge → ECS import job - ✅ Done

**From eventbridge-import.tf:**

- `aws_cloudwatch_event_rule.s3_metadata_object_created`
- `aws_iam_role.events_to_ecs`
- `aws_iam_policy.events_to_ecs`
- `aws_iam_role_policy_attachment.events_to_ecs_attach`
- `aws_cloudwatch_event_target.run_import_task`

**To → `module.eventbridge_import`**

``` bash
terraform state mv aws_cloudwatch_event_rule.s3_metadata_object_created \
  module.eventbridge_import.aws_cloudwatch_event_rule.s3_metadata_object_created
terraform state mv aws_iam_role.events_to_ecs \
  module.eventbridge_import.aws_iam_role.events_to_ecs
terraform state mv aws_iam_policy.events_to_ecs \
  module.eventbridge_import.aws_iam_policy.events_to_ecs
terraform state mv aws_iam_role_policy_attachment.events_to_ecs_attach \
  module.eventbridge_import.aws_iam_role_policy_attachment.events_to_ecs_attach
terraform state mv aws_cloudwatch_event_target.run_import_task \
  module.eventbridge_import.aws_cloudwatch_event_target.run_import_task
```

## VPC Endpoints - ✅ Done

**From vpc-endpoints.tf:**

- `aws_security_group.vpce`
- `aws_security_group_rule.vpce_ingress_from_tasks`
- `aws_vpc_endpoint.secretsmanager`
- `aws_vpc_endpoint.ecr_api`
- `aws_vpc_endpoint.ecr_dkr`
- `aws_vpc_endpoint.logs`

**To → `module.vpc_endpoints`**

``` bash
terraform state mv aws_security_group.vpce \
  module.vpc_endpoints.aws_security_group.vpce
terraform state mv aws_security_group_rule.vpce_ingress_from_tasks \
  module.vpc_endpoints.aws_security_group_rule.vpce_ingress_from_tasks
terraform state mv aws_vpc_endpoint.secretsmanager \
  module.vpc_endpoints.aws_vpc_endpoint.secretsmanager
terraform state mv aws_vpc_endpoint.ecr_api \
  module.vpc_endpoints.aws_vpc_endpoint.ecr_api
terraform state mv aws_vpc_endpoint.ecr_dkr \
  module.vpc_endpoints.aws_vpc_endpoint.ecr_dkr
terraform state mv aws_vpc_endpoint.logs \
  module.vpc_endpoints.aws_vpc_endpoint.logs
```
