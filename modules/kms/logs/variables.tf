variable "region" {
  type = string
  }

variable "aws_acct_num" {
  type        = string
  description = "AWS account number."
  }

variable "name_prefix" {
  type = string
  }

variable "tags" {
  type    = map(string)
  default = {}
  }

# Optional: extra principals (roles/users) that can administer the key
variable "admin_principal_arns" {
  type        = list(string)
  default     = []
  description = "Additional IAM principals with KMS admin permissions."
}
