# Amazon ECS Task Execution IAM Role

태스크 실행 IAM 역할은 Amazon ECS 컨테이너 및 ECS Fargate 에 사용자를 대신하여 AWS ECS Task 정의를 포함하여 ECS 관련 API 호출을 수행할 권한을 부여합니다.

```
locals {
  ecs_task_role_name = "ecsTaskExecutionRole"
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = local.ecs_task_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = { Name = local.ecs_task_role_name }
}

data "aws_iam_policy" "ecs_task_execution_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution_policy.arn
}
```