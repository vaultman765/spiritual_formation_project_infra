variable "role_name" { type = string }
variable "oidc_provider_arn" { type = string }

variable "github_owner" { type = string } # e.g., "vaultman765"
variable "github_repo" { type = string }  # e.g., "spiritual_formation_project"
variable "github_refs" {
  type    = list(string)
  default = ["refs/heads/main"]
}
