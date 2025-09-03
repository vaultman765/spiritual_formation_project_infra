variable "name_prefix" {
  type        = string
  description = "Prefix for naming"
}

variable "site_origin" {
  type        = string
  description = "Canonical site origin (e.g. https://www.catholicmentalprayer.com)"
}

variable "api_base" {
  type        = string
  description = "Base API URL (e.g. https://api.catholicmentalprayer.com)"
}
