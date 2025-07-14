locals {
  role_name = var.ecs_task_role_name == null ? "${var.context.project}EcsTaskExecutionRole" : var.ecs_task_role_name

  trusted_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ecs-tasks.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )

  ecs_task_execution_policies = merge({ AmazonECSTaskExecutionRolePolicy = data.aws_iam_policy.this[0].arn },
    local.create_custom_policy ? { EcsTaskExecutionPolicy = aws_iam_policy.this[0].arn } : {}
  )

}

resource "aws_iam_role" "this" {
  count              = var.create && var.create_ecs_task_execution_role ? 1 : 0
  name               = local.role_name
  assume_role_policy = local.trusted_role_policy
  tags = merge(var.context.tags, {
    Name = local.role_name
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this[0].id
  for_each   = local.ecs_task_execution_policies
  policy_arn = each.value
  depends_on = [
    aws_iam_role.this,
    aws_iam_policy.this
  ]
}
