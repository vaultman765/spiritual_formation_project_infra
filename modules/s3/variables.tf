variable "project" { type = string }
variable "env" { type = string }

# names resolve to: spiritual-formation-<env>, spiritual-formation-frontend-<env>
variable "metadata_bucket_name" {
  type    = string
  default = ""
}

# Default false since cloudfront_site owns the bucket
variable "create_frontend_bucket" {
  type    = bool
  default = false
}

# Optional: only used if you want a policy here
variable "frontend_bucket_name" {
  type    = string
  default = ""
}

variable "static_admin_distribution_id" {
  description = "CloudFront distribution ID for static admin host."
  type        = string
}

# Only needed if you intend to attach an OAC-based policy from this module.
# If you keep using OAI in cloudfront_site (recommended), you can leave this empty.
variable "frontend_distribution_id" {
  type    = string
  default = ""
}

variable "aws_acct_num" {
  type = string
}
variable "log_bucket_name" {
  type    = string
  default = null
}

