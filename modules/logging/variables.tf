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