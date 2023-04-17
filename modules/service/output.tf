output "task_definition_id" {
  description = "ID of the ECS Task Definition"
  value       = try(aws_ecs_task_definition.this.id, "")
}

output "service_id" {
  description = "ID of the ECS Application Service"
  value       = try(aws_ecs_service.this.id, "")
}


output "service_name" {
  description = "Name of the ECS Application Service"
  value       = local.service_name
}

output "container_name" {
  description = "Name of the ECS Application Container"
  value       = local.container_name
}


output "awslogs_group_name" {
  description = "Name of the CloudWatch Log Group"
  value       = local.awslogs_group_name
}

