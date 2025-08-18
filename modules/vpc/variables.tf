variable "project" { type = string }
variable "env" { type = string }

# Allow turning the whole VPC on/off (used by staging kill-switch)
variable "enabled" {
  type        = bool
  description = "Create the VPC and all child resources when true."
  default     = true
}

# Stable naming/tagging
variable "name_prefix" {
  type        = string
  description = "Prefix for naming/tagging VPC resources (e.g., sf-staging)."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to all resources."
  default     = {}
}

variable "cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

# Two AZs by default; supply exactly two CIDR lists below.
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

# NAT modes: "single" (1 NAT), "per_az" (1 per AZ), "none"
variable "nat_gateway_mode" {
  type    = string
  default = "single"
  validation {
    condition     = contains(["single", "per_az", "none"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: single, per_az, none"
  }
}
