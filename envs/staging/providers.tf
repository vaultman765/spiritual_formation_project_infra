provider "aws" {
  alias  = "us_east_1"
  region = var.region
  default_tags {
    tags = {
      Project = var.project
      Env     = var.env
      Managed = "Terraform"
    }
  }
}