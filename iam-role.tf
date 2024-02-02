locals {
  role_name = var.ecs_task_role_name == null ? "${var.context.project}EcsTaskExecutionRole" : var.ecs_task_role_name
}

data "aws_iam_policy_document" "ecs" {
  count = var.create && var.create_ecs_task_execution_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs" {
  count = var.create && var.create_ecs_task_execution_role ? 1 : 0

  name               = local.role_name
  assume_role_policy = concat(data.aws_iam_policy_document.ecs.*.json, [""])[0]
  tags               = merge(
    var.context.tags,
    { Name = local.role_name }
  )
}

data "aws_iam_policy" "ecs" {
  count = var.create && var.create_ecs_task_execution_role ? 1 : 0
  name  = "AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  count = var.create && var.create_ecs_task_execution_role ? 1 : 0

  role       = concat(aws_iam_role.ecs.*.name, [""])[0]
  policy_arn = concat(data.aws_iam_policy.ecs.*.arn, [""])[0]
}
