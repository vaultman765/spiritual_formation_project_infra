# terraform-docs:begin:inputs
# Inputs:
# - role_name: Name for IAM role.
# - github_org: GitHub org/owner.
# - github_repo: GitHub repo name.
# - bucket_name: S3 bucket to deploy to.
# - cloudfront_distribution_id: CloudFront distribution to invalidate.
# - policy_extra_json: Optional extra JSON policy statements (list) to merge.
# terraform-docs:end:inputs

variable "role_name" { type = string }
variable "github_org" { type = string }
variable "github_repo" { type = string }
variable "bucket_name" { type = string }
variable "cloudfront_distribution_id" { type = string }
variable "policy_extra_json" {
  type    = list(object({ Sid = string, Effect = string, Action = list(string), Resource = list(string) }))
  default = []
}
