variable "role_name" { type = string }
variable "oidc_provider_arn" { type = string }

variable "github_owner" { type = string }
variable "github_repo" { type = string }

# Example entries:
#   "ref:refs/heads/main"
#   "ref:refs/heads/staging"
#   "ref:refs/tags/v*"
variable "github_refs" {
  type = list(string)
  # Optional: sensible default allows all branches (keep or remove the default to force explicit refs)
  default = ["ref:refs/heads/*"]
}