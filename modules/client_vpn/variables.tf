variable "project" { type = string }
variable "env" { type = string }
variable "name_prefix" { type = string }
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) } # associate at least 2 AZs
variable "server_certificate_arn" { type = string }   # ACM ARN from Step 1
variable "client_cidr_block" {
  type    = string
  default = "10.254.0.0/22"
}
variable "split_tunnel" {
  type    = bool
  default = true
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "enable_connection_logs" {
  type    = bool
  default = true
}
