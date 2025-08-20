variable "project" { type = string }
variable "env" { type = string }
variable "name_prefix" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

variable "metadata_bucket" { type = string }

# From your ecs_import module
variable "cluster_arn" { type = string }
variable "task_definition_arn" { type = string }
variable "task_role_arn" { type = string }
variable "task_execution_role_arn" { type = string }

# Networking for the ECS task
variable "private_subnet_ids" { type = list(string) }
variable "security_group_id" { type = string }
