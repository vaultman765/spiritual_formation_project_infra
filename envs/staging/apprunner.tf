module "apprunner" {
  source = "../../modules/apprunner"

  project = var.project
  env     = var.env
  region  = var.region

  enabled     = var.staging_infra_enabled
  name_prefix = var.name_prefix

  auto_deployments_enabled = var.apprunner_auto_deployments

  image_repository_url = module.ecr_backend.repo_url
  image_tag            = var.apprunner_image_tag

  log_kms_key_arn = module.kms_logs.kms_key_arn

  app_port = 8000
  cpu      = var.apprunner_cpu
  memory   = var.apprunner_memory

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.rds.rds_sg_id
  db_port            = 5432

  rds_secret_arn    = var.rds_secret_arn
  django_secret_arn = var.django_secret_arn


  s3_bucket_name = var.metadata_bucket

  health_check_path  = "/health/"
  log_retention_days = 5

  # ---- Plain environment variables ----
  env_vars = {
    ENV            = var.env
    DEBUG          = "False"
    AWS_REGION     = var.region
    S3_BUCKET_NAME = var.metadata_bucket
    APP_ROLE       = "web"

    DB_SSL = "True"

    # Django / CORS / CSRF
    ALLOWED_HOSTS          = var.allowed_hosts
    CORS_ALLOW_ALL_ORIGINS = "False"
    CORS_ALLOW_CREDENTIALS = "True"
    CORS_ALLOWED_ORIGINS   = var.cors_allowed_origins
    CSRF_TRUSTED_ORIGINS   = var.csrf_trusted_origins

    STATIC_CDN_DOMAIN = replace(module.static_admin_staging.alias_record_fqdn, "/\\.$/", "")
    MEDIA_CDN_DOMAIN  = replace(module.static_admin_staging.alias_record_fqdn, "/\\.$/", "")
  }

  # ---- Secrets (NOTE the :KEY:: suffixes) ----
  env_secrets = {
    DB_NAME     = "${var.rds_secret_arn}:dbname::"
    DB_USER     = "${var.rds_secret_arn}:username::"
    DB_PASSWORD = "${var.rds_secret_arn}:password::"
    DB_HOST     = "${var.rds_secret_arn}:host::"
    DB_PORT     = "${var.rds_secret_arn}:port::"
    SECRET_KEY  = "${var.django_secret_arn}:SECRET_KEY::"
  }
}
