variable "project" { type = string }
variable "env" { type = string }
variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  bucket_name = "tfstate-${var.project}-${var.env}-${var.region}"
  lock_table  = "tfstate-lock-${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
  }
}

output "state_bucket" { value = local.bucket_name }
output "lock_table" { value = local.lock_table }
output "state_bucket_arn" { value = aws_s3_bucket.state.arn }
