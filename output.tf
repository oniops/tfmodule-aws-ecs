output "ecs_cluster_id" {
  description = "ID of the ECS Cluster"
  value       = concat(aws_ecs_cluster.this.*.id, [""])[0]
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS Cluster"
  value       = concat(aws_ecs_cluster.this.*.arn, [""])[0]
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = local.cluster_name
}

output "ecs_task_execution_role_arn" {
  description = "The ARN of ECS task execution role"
  value       = concat(aws_iam_role.ecs_task_execution_role.*.arn, [""])[0]
}
