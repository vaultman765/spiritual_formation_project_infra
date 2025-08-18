output "cluster_arn" { value = aws_ecs_cluster.this.arn }
output "task_definition_arn" { value = aws_ecs_task_definition.this.arn }
output "task_role_arn" { value = aws_iam_role.task.arn }
output "execution_role_arn" { value = aws_iam_role.execution.arn }
output "log_group" { value = aws_cloudwatch_log_group.this.name }
