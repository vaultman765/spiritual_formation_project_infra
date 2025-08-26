variable "project" { type = string }
variable "env" { type = string }
variable "name_prefix" { type = string }
variable "hosted_zone_id" { type = string }
variable "from_domains" { type = list(string) }
variable "to_domain" { type = string }
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "browser_cache_seconds" {
  type    = number
  default = 300
}

variable "comment" {
  type    = string
  default = ""
}

variable "extra_tags" {
  type    = map(string)
  default = {}
}

variable "response_headers_policy_id" {
  type    = string
  default = null
}

variable "log_bucket_name" {
  type    = string
  default = null
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
variable "web_acl_arn" {
  type        = string
  default     = null
  description = "Optional WAFv2 Web ACL ARN to attach to this distribution"
}