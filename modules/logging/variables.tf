variable "name_prefix" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "Optional explicit bucket name. If empty, a unique name will be derived."
}
variable "kms_key_arn" {
  description = "ARN of the KMS key to use for encrypting the logs bucket"
  type        = string
  default     = null
}