output "rule_name" { value = aws_cloudwatch_event_rule.s3_metadata_object_created.name }
output "role_arn" { value = aws_iam_role.events_to_ecs.arn }
output "target_id" { value = aws_cloudwatch_event_target.run_import_task.id }
