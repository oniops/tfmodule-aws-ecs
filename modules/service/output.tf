output "ecs_task_definition_id" {
  description = "ID of the ECS Task Definition"
  value       = aws_ecs_task_definition.this.id
}

output "ecs_service_id" {
  description = "ID of the ECS Application Service"
  value       = concat(aws_ecs_service.this.id, [""])[0]
}
