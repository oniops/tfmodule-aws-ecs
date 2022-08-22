locals {
  ecs_task_role_name = var.ecs_task_role_name == null ? "${var.context.project}EcsTaskExecutionRole" : var.ecs_task_role_name
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  count = var.create_ecs && var.create_ecs_task_execution_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  count = var.create_ecs && var.create_ecs_task_execution_role ? 1 : 0

  name               = local.ecs_task_role_name
  assume_role_policy = concat(data.aws_iam_policy_document.ecs_task_assume_role.*.json, [""])[0]
  tags               = merge(var.context.tags,
    { Name = local.ecs_task_role_name }
  )
}

data "aws_iam_policy" "ecs_task_execution_policy" {
  count = var.create_ecs && var.create_ecs_task_execution_role ? 1 : 0

  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  count = var.create_ecs && var.create_ecs_task_execution_role ? 1 : 0

  role       = concat(aws_iam_role.ecs_task_execution_role.*.name, [""])[0]
  policy_arn = concat(data.aws_iam_policy.ecs_task_execution_policy.*.arn, [""])[0]
}
