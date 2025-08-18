# Spiritual Formation – AWS IaC Migration Plan

**Last updated:** 2025-08-09  
**Owner:** You + “AWS Cloud Architect & developer” GPT  
**Scope:** Replace all console-created resources with Terraform-managed infrastructure. Prod is not live; we can build, test, and iterate freely.

---

## Why IaC right now

- No live traffic → zero-risk to iterate.
- Reproducible, reviewable changes via PRs.
- Fast rollbacks and environment parity (staging/prod).

---

## Guiding Principles

- Everything in Terraform: VPC, RDS, S3, App Runner, ECS (one-off task), IAM, EventBridge, Route 53, ACM, CloudFront, ECR, logging.
- GitHub Actions with OIDC (no static AWS keys).
- Least-privilege IAM; encrypt at rest (KMS-managed).
- Private subnets for RDS/ECS; NAT or VPC endpoints for egress.
- App Runner uses VPC Connector to reach RDS.
- Production “source of truth” checksum only in S3.

---

## Repo Layout (infra)

```plaintext
infra/
  README.md
  .gitignore
  .terraform-version

  bootstrap/                 # one-time: create tf state bucket + lock table
    main.tf
    variables.tf
    versions.tf

  global/                    # shared config for all envs
    backend.tf               # remote state (S3 + DynamoDB) used by envs/*
    providers.tf             # aws provider + default tags
    versions.tf
    tags.tf

  modules/                   # reusable building blocks
    vpc/
      main.tf
      variables.tf
      outputs.tf
    rds/
      main.tf
      variables.tf
      outputs.tf
    s3/
      main.tf
      variables.tf
      outputs.tf
    ecr/
      main.tf
      variables.tf
      outputs.tf
    apprunner/
      main.tf
      variables.tf
      outputs.tf
    ecs_import_job/
      main.tf
      variables.tf
      outputs.tf
    iam/
      github_oidc/
        main.tf
        variables.tf
        outputs.tf
      roles/
        main.tf
        variables.tf
        outputs.tf
      policies/              # JSON templates if needed
        metadata_rw.json
    eventbridge/
      main.tf
      variables.tf
      outputs.tf
    route53_acm/
      main.tf
      variables.tf
      outputs.tf
    cloudfront/
      main.tf
      variables.tf
      outputs.tf
    secrets_manager/
      main.tf
      variables.tf
      outputs.tf
    logging/
      main.tf
      variables.tf
      outputs.tf

  envs/
    staging/
      main.tf
      variables.tf
      terraform.tfvars.example
    prod/
      main.tf
      variables.tf
      terraform.tfvars.example

  pipelines/                 # CI/CD samples (optional, nice to have)
    .github/
      workflows/
        infra-plan-apply.yml
```

### Terraform State Backend

- S3 bucket `tfstate-<account>-<region>` (versioned, private, SSE-S3/KMS)
- DynamoDB table `tfstate-lock`
- Workspaces or separate `envs/*` for staging/prod

---

## Variables to Standardize

- `project = "spiritual-formation"`
- `env = "staging" | "prod"`
- `region = "us-east-1"`
- `domain_names = ["meditationwithchrist.com","catholicmentalprayer.com"]`
- `db`: engine, version, instance_class, storage_gb, multi_az, backup_window, maintenance_window
- `vpc`: cidr, az_count (2), private/public subnet cidrs
- `s3_buckets`:
  - `metadata_bucket = "spiritual-formation-prod"` (staging can be `-staging`)
  - `frontend_bucket = "spiritual-formation-frontend-<env>"`
- `apprunner`: image repo, cpu/mem, health path, min/max concurrency
- `ecs`: task cpu/mem, subnets/SG IDs
- `route53`: hosted zone IDs or create zones
- `github_org`/`repo` for OIDC trust

---

## Module Responsibilities (high level)

### vpc/

- VPC, 2× public + 2× private subnets, NAT (1 per AZ or 1 shared)
- Route tables, IGW, NATGW, default security groups
- (Optional) VPC endpoints: S3 Gateway; interface endpoints for Secrets Manager, ECR (api+dkr), CloudWatch Logs

**Outputs:** `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `vpc_endpoint_sg_id`

### rds/

- PostgreSQL (prod: Multi-AZ on; staging optional)
- Parameter group (enforce SSL), subnet group, SG allowing 5432 **from** App Runner VPC connector SG + ECS task SG
- Backups, auto minor version upgrade, deletion protection (prod)

**Outputs:** `db_endpoint`, `db_port`, `db_sg_id`

### s3/

- Buckets:
  - `spiritual-formation-<env>` for `metadata/**` + `checksum/.mental_prayer_checksums.json`
  - `spiritual-formation-frontend-<env>` for static site
- Block Public Access = true; default encryption
- Bucket policies for access from ECS/App Runner roles (least-priv)
- (Optional) lifecycle rules on metadata

### ecr/

- Repos for `backend` (Django/App Runner image) and `import-job` (can reuse backend image)
- Immutable tags option; scan on push

### apprunner/

- Service backed by ECR image
- VPC Connector (private subnets) for DB access
- Env vars via Secrets Manager/SSM; health check path (`/api/health/` or `/admin/login/`)
- Auto-scaling config; CloudWatch logs

### ecs_import_job/

- Cluster, task definition, and task/execution roles
- Task in private subnets (egress via NAT or endpoints)
- Task role permissions:
  - `s3:GetObject/PutObject/ListBucket` on metadata & checksum keys
  - `secretsmanager:GetSecretValue` for DB creds / SECRET_KEY
  - `logs:CreateLogStream/PutLogEvents`
- Execution role for pulling image + logs
- CloudWatch log group

### eventbridge/

- Rule filtering S3 `ObjectCreated:*` in `metadata/` prefix
- Target: ECS RunTask with task overrides (optional)
- IAM target role to `ecs:RunTask` + `iam:PassRole`

### route53_acm/

- Hosted zones (if you own registrar) or use existing
- ACM certs in us-east-1 for:
  - App Runner custom domains
  - CloudFront (frontend)
- DNS records for App Runner custom domain mapping

### cloudfront/

- Distribution fronting the frontend S3 bucket
- OAC (origin access control) to keep bucket private
- `index.html`/403→200 SPA behavior, gzip/brotli

### secrets_manager/

- **Do not store secrets in `.env`** for cloud
- Secrets:
  - `django/secret_key`
  - `rds/app_user_password`
  - Optional: `django/settings` JSON blob
- Resource policies: allow read from App Runner + ECS only

### logging/

- CloudWatch log groups for App Runner, ECS task, (optionally) VPC Flow Logs

---

## Deployment Order (Cutover Sequence)

1. **IAM (global)** – base roles, GitHub OIDC provider, Terraform Cloud/Actions role(s).
2. **VPC** – networking, NAT, (optionally) endpoints.
3. **RDS** – DB subnet group, SGs, instance; create Secrets Manager entries.
4. **S3** – metadata + frontend buckets with policies.
5. **ECR** – create repos for images.
6. **App Runner** – service using ECR image; VPC connector; health check.
7. **ECS (import job)** – task definition/roles/cluster/logs.
8. **EventBridge** – rule + target to run ECS task on S3 `ObjectCreated` under `metadata/`.
9. **Route 53 + ACM** – certs + DNS for App Runner; CloudFront for frontend.
10. **CloudFront** – point to frontend S3; deploy.

You can apply each step independently in staging; prod follows once validated.

---

## CI/CD (GitHub Actions)

- **Workflow: infra**
  - `on: pull_request` → `terraform fmt/validate/plan`
  - `on: push to main` → `terraform apply`
  - Auth via **GitHub OIDC** → AWS role with limited perms
- **Workflow: backend**
  - Build + push image to ECR (cache if needed)
  - Trigger App Runner deploy (or App Runner auto-detects new image tag)
- **Workflow: metadata**
  - On changes under `/metadata/**` in `main`:
    - Sync to S3 `s3://spiritual-formation-<env>/metadata`
    - (Alt A) Let **EventBridge** trigger ECS task (recommended)
    - (Alt B) Directly `RunTask` from GH (requires OIDC role)

---

## Import Job – Desired Behavior

- Task command:  
  `python manage.py import_arc --arc-id all --skip-unchanged`
- I/O:
  - Read checksum: `s3://<bucket>/checksum/.mental_prayer_checksums.json`
  - Read YAML under `metadata/**`
  - Update RDS
  - Write updated YAML back to S3 (adds `# Last imported into DB:` header)
  - Write updated checksum back to S3
- Observability: CW logs + task exit code alarms (optional)

---

## Security Baseline

- **Rotate any secrets committed to `.env`** (AWS keys, DB password, Django SECRET_KEY).
- App Runner & ECS use **role-based** access (no access keys).
- RDS security group allows 5432 **only** from:
  - App Runner VPC connector SG
  - ECS task SG
  - (Optionally) admin IP via bastion/SSM
- Enforce SSL to RDS in parameter group + Django settings.
- Buckets private; CloudFront OAC for frontend.
- KMS encryption by default (S3, RDS storage, Secrets Manager).
- VPC endpoints (optional) to reduce NAT costs and tighten egress.

---

## Validation Checklist

- [ ] `terraform validate/plan` clean in staging
- [ ] App Runner health check passes (`/api/health/`)
- [ ] App connects to RDS (migrations OK)
- [ ] S3 metadata sync from GH works
- [ ] EventBridge → ECS task fires on new object, task succeeds
- [ ] Checksum file updates in S3
- [ ] YAML files in S3 gain `Last imported into DB:` header
- [ ] CloudFront serves frontend; S3 bucket not public
- [ ] Secrets readable only by the intended roles
- [ ] Alarms/logs visible in CloudWatch

---

## Runbooks

### Manually trigger import

- Upload a test file under `metadata/` or call `ecs:RunTask` with the import task definition.

### Rollback (infra)

- Revert PR → `terraform apply` to previous state.

### Rollback (app)

- Re-deploy older ECR tag; App Runner will roll back.

---

## Immediate To-Dos

- [ ] Create `infra/` skeleton and Terraform backend (state bucket + lock table).
- [ ] Set up GitHub OIDC role for CI (no long-lived AWS keys).
- [ ] **Rotate all secrets found in local `.env`** and remove them from any repos/issues.
- [ ] Decide NAT vs. endpoints mix (cost vs. simplicity).
- [ ] Confirm health check path and environment variables expected by Django.

---

## Notes

- Staging and prod can share account, but prefer separate or at least separate VPCs.
- App Runner VPC connector requires private subnets with route to RDS. Ensure SG rules are set accordingly.
- Import job can reuse the backend image; keep task lightweight.
