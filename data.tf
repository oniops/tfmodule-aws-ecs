data "aws_iam_policy" "this" {
  count = var.create && var.create_ecs_task_execution_role ? 1 : 0
  name  = "AmazonECSTaskExecutionRolePolicy"
}
