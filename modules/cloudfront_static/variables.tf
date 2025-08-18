# terraform-docs:begin:inputs
# Inputs:
# - project: Project tag.
# - env: Environment tag.
# - region: S3 bucket region.
# - bucket_name: Private S3 bucket that stores Django static (and/or media).
# - origin_path: Optional S3 origin path (e.g., "/django/static"). Default "".
# - domain_name: Public hostname for CloudFront (e.g., static.staging.example.com).
# - hosted_zone_name: Route 53 public zone name (e.g., example.com).
# - acm_certificate_arn: ACM cert ARN in us-east-1 for domain_name.
# - price_class: CloudFront price class (staging default: PriceClass_100).
# - default_ttl / max_ttl / min_ttl: Cache TTLs (seconds).
# terraform-docs:end:inputs

variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }

variable "bucket_name" { type = string }
variable "origin_path" {
  type    = string
  default = ""
} # must start with "/" or be empty

variable "domain_name" { type = string }
variable "hosted_zone_name" { type = string }
variable "acm_certificate_arn" { type = string }

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
variable "default_ttl" {
  type    = number
  default = 86400
}
variable "max_ttl" {
  type    = number
  default = 604800
}
variable "min_ttl" {
  type    = number
  default = 0
}
