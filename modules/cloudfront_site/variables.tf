# terraform-docs:begin:inputs
# Inputs:
# - project: Project tag.
# - env: Environment tag.
# - region: AWS region for S3 bucket (CloudFront is global; cert must be in us-east-1).
# - domain_name: The CNAME for the site (e.g., staging.catholicmentalprayer.com).
# - hosted_zone_name: Route 53 hosted zone name (e.g., catholicmentalprayer.com).
# - acm_certificate_arn: ACM cert ARN in us-east-1 for domain_name.
# - bucket_name: Optional explicit S3 bucket name (defaults to derived from domain_name).
# - price_class: CloudFront price class (default: PriceClass_100).
# - spa_mode: If true, map 403/404 to /index.html for SPA routing.
# - default_ttl: Default cache TTL seconds (default 3600).
# - max_ttl: Max cache TTL seconds (default 86400).
# - min_ttl: Min cache TTL seconds (default 0).
# terraform-docs:end:inputs

variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }
variable "name_prefix" { type = string }

variable "domain_name" {
  description = "Full hostname users will hit (e.g. staging.catholicmentalprayer.com)."
  type        = string
}

variable "hosted_zone_name" {
  description = "Existing public Route53 hosted zone (e.g. catholicmentalprayer.com)."
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN (must be in us-east-1)."
  type        = string
}

variable "bucket_name" {
  description = "Optional S3 bucket name; if empty, derived from domain_name."
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_100"
}

variable "spa_mode" {
  description = "If true, map 403/404 to /index.html for SPA routing."
  type        = bool
  default     = true
}

variable "default_ttl" {
  type    = number
  default = 3600
}

variable "max_ttl" {
  type    = number
  default = 86400
}

variable "min_ttl" {
  type    = number
  default = 0
}
variable "response_headers_policy_id" {
  type = string
}
variable "log_bucket_name" {
  type    = string
  default = null
}
variable "web_acl_arn" {
  type        = string
  default     = null
  description = "Optional WAFv2 Web ACL ARN to attach to this distribution"
}
variable "geo_restriction_type" {
  type        = string
  default     = "none"
  description = "Method to use for restricting distribution (none, whitelist, blacklist)"
}

variable "geo_locations" {
  type        = list(string)
  default     = []
  description = "List of country codes to block or allow (depends on geo_restriction_type)"
}
variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the logs bucket"
  type        = string
  default     = null
}
