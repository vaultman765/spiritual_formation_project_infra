variable "repository_name" {
  type = string
}
variable "scan_on_push" {
  type    = bool
  default = true
}
variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}
variable "kms_key_arn" {
  type        = string
  description = "ARN of KMS key for ECR repository encryption"
  default     = null
}
