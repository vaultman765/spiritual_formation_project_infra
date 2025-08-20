
# Production Rollout Order (spiritual formation project)

Safe, dependency-aware sequence for applying Terraform to `envs/prod`.

---

## Step 1: Global / Account-level

- `module.iam.github_oidc` (OIDC provider)
- `module.iam.github_oidc_role` (per repo)
- ⚠️ Temporary: AdminAccess allowed, remove after roles are least-priv.

## Step 2: Networking

- `module.vpc` (VPC, subnets, NAT)
- `module.vpc_endpoints` (Secrets Manager, ECR API/DKR, Logs)

## Step 3: Data Layer

- `module.rds` (Postgres DB)
- Secrets Manager integration auto-writes DB credentials.

## Step 4: Container Registry

- `module.ecr` (backend, workers, import job)
- Update CI to push to prod repos.

## Step 5: App Runner

- `module.apprunner`
  - VPC connector + SG for DB access.
  - Env vars (DB secret, Django settings, etc).
  - Health checks + scaling config.

## Step 6: Static & SPA

- `module.cloudfront_static` → Django static/media.
- `module.cloudfront_site` → React/Vite SPA.

## Step 7: Domains & Certificates

- `module.route53_acm` → API, SPA, static.
- `module.apprunner_custom_domain` (or inline) → App Runner HTTPS.

## Step 8: Redirects

- `module.redirect_domain` → apex → canonical.

## Step 9: Background Jobs

- `module.eventbridge_import_job` → ECS/Fargate triggered tasks.

## Step 10: Cutover & Post

- Smoke test: API, SPA, static, auth flows.
- Snapshot DB once stable.
- Remove AdminAccess → tighten to least-priv.
