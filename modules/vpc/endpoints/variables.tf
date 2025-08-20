variable "project" { type = string }
variable "env" { type = string }

variable "name_prefix" {
  type    = string
  default = ""
}
variable "security_group_name" {
  type    = string
  default = ""
}

variable "region" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }

variable "allowed_sg_ids" {
  description = "Map of name -> SG ID that can reach the VPC endpoints (ingress 443)"
  type        = map(string)
  default     = {}
}

variable "allow_from_vpc_cidr" {
  description = "Add an ingress rule allowing 443 from the entire VPC CIDR"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_secretsmanager" {
  type    = bool
  default = true
}
variable "enable_ecr_api" {
  type    = bool
  default = true
}
variable "enable_ecr_dkr" {
  type    = bool
  default = true
}
variable "enable_logs" {
  type    = bool
  default = true
}
