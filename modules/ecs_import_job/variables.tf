variable "project" { type = string }
variable "env" {
  type    = string
  default = "staging"
}

variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string } # ecs tasks sg

variable "container_image" { type = string } # e.g. "<acct>.dkr.ecr.us-east-1.amazonaws.com/spiritual-formation-backend:latest"
variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "metadata_bucket" { type = string } # e.g. spiritual-formation-staging
variable "rds_secret_arn" { type = string }  # from rds module output
variable "django_secret_arn" {
  type    = string
  default = ""
}

variable "cpu" {
  type    = number
  default = 256
}
variable "memory" {
  type    = number
  default = 512
}
variable "log_retention_days" {
  type    = number
  default = 7
}
