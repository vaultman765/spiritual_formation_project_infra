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