output "ecs_task_definition_id" {
  description = "ID of the ECS Task Definition"
  value       = try(aws_ecs_task_definition.this.id, "")
}

output "ecs_service_id" {
  description = "ID of the ECS Application Service"
  value       = try(aws_ecs_service.this.id, "")
}
