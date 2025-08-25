module "s3" {
  source       = "../../modules/s3"
  project      = var.project
  env          = var.env
  aws_acct_num = var.aws_acct_num

  log_bucket_name = module.logging.log_bucket_name

  # Keep metadata bucket + policy (needed for admin/static and docs/images)
  static_admin_distribution_id = module.static_admin_prod.distribution_id

  # Do NOT create or manage a separate frontend bucket here.
  create_frontend_bucket   = false
  frontend_bucket_name     = "" # unused
  frontend_distribution_id = "" # unused
}