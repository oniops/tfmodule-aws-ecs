locals {
  policy_name                  = "${var.context.project}EcsTaskExecutionPolicy"
  create_custom_policy         = var.create && var.create_ecs_task_execution_role && length(var.custom_task_execution_policy) > 1
  custom_task_execution_policy = jsonencode(var.custom_task_execution_policy)
}

resource "aws_iam_policy" "this" {
  count  = local.create_custom_policy ? 1 : 0
  name   = local.policy_name
  policy = local.custom_task_execution_policy
  tags = merge(local.tags, {
    Name = local.policy_name
  })
}
