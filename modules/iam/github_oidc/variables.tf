variable "project" { type = string }
variable "env" { type = string }

# Your GitHub org/user and the repo that holds the Terraform code (infra repo)
variable "github_owner" { type = string } # e.g., "vaultman765"
variable "github_repo" { type = string }  # e.g., "spiritual_formation_project_infra"

# Allow one or more refs to assume the role (e.g., main + PR merges)
variable "github_refs" {
  type    = list(string)
  default = ["refs/heads/main"]
}

# Quick start: attach admin while bootstrapping; we’ll tighten later
variable "attach_admin_policy" {
  type    = bool
  default = true
}
