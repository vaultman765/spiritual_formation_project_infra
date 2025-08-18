variable "project" { type = string }
variable "env" { type = string }
variable "region" { type = string }

variable "domain_name" {
  description = "FQDN to issue a cert for (e.g., api.staging.example.com)"
  type        = string
}

variable "root_domain_name" {
  description = "Root domain (e.g., example.com)"
  type        = string
}

variable "manage_zone" {
  description = "If true, create the hosted zone. If false, reuse existing zone."
  type        = bool
  default     = true
}
variable "subject_alternative_names" {
  type    = list(string)
  default = []
}