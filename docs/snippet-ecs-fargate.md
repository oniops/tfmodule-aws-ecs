# ECS Fargate Cluster 구성 

## ECS Fargate Cluster 구성 워크 플로우
주요 구성 흐름은 아래와 같습니다.

```
1. context 정보 구성 - module "ctx" 

2. VPC 구성 - module "vpc"
   ECS 클러스터에 Public ALB 와 연결 되었다면, NAT 게이트웨이가 하나 이상 구성 되어야 합니다.  

3. ECS Fargate 클러스터 구성 - module "ecs"
 
4. Nginx 작업 정의 구성 - resource "aws_ecs_task_definition"
   Nginx Docker 컨테이너를 실행하기 위한 스펙을 정의 합니다. (리소스, 포트 매핑, 컨테이너 이미지 등)
   특히, Nginx 의 경우 CPU 는 512, Memory 는 1024 이상 필요로 합니다.

5. Public ALB 를 위한 보안 그룹 구성 - "aws_security_group" "public_alb"
   ALB 는 보안 그룹을 1개 이상 필수로 구성 되어야 하며, ALB 전용 보안 그룹을 신규로 만들 것을 권고 합니다.

6. Public ALB 구성 
   ALB 기본 정보. 연결될 서브네트워크, 서비스 리스너, 보안 그룹, TargetGroup 등 주요 리소스를 구성 합니다.

7. ECS Service 구성
   Nginx 작업 정의를 기반으로 nginx-test-servcie 를 구동 합니다.
   주요 구성 정보로 서비스가 배치될 서브 네트워크, 포트 바인딩, 로드 밸런서 연결 등을 정의해야 합니다. 
```


## Sample
본 예제는 기능 검증을 목적으로 최소로 구성 되었으므로 개발 및 운영 환경에 적용하지 마시기 바랍니다.

```
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

module "ctx" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-context.git"

  context = {
    aws_profile = "terran"
    region      = "ap-northeast-2"
    project     = "waffle"
    environment = "PoC"
    owner       = "owner@academyiac.cf"
    team        = "DX"
    cost_center = "20211120"
    domain      = "academyiac.cf"
    pri_domain  = "mydemo.local"
  }
}

data "aws_availability_zones" "this" {
  state = "available"
}

module "vpc" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-vpc.git"

  context = module.ctx.context
  cidr    = "172.3.0.0/16"

  azs = [data.aws_availability_zones.this.zone_ids[0], data.aws_availability_zones.this.zone_ids[1]]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_names  = ["pub-a1", "pub-b1"]
  public_subnets       = ["172.3.11.0/24", "172.3.12.0/24"]
  public_subnet_suffix = "pub"

  private_subnet_names = ["was-a1", "was-b1"]
  private_subnets      = ["172.3.31.0/24", "172.3.32.0/24"]

  create_private_domain_hostzone = false

  depends_on = [module.ctx]
}

module "ecs" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-ecs.git"

  context            = module.ctx.context
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  container_insights = true

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
    }
  ]

  depends_on = [module.vpc]
}

resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-test"
  requires_compatibilities = ["FARGATE", "EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 512
  memory                   = 1024
  container_definitions    = <<EOF
[
  {
    "name": "nginx",
    "image": "nginx:latest",
    "networkMode" : "awsvpc",
    "essential": true,
    "cpu": 512,
    "memory": 1024,
    "portMappings": [
      {
        "hostPort": 80,
        "protocol": "tcp",
        "containerPort": 80
      }
    ]
  }
]
EOF

  tags       = merge(module.ctx.tags, { Name = "nginx-test" })
  depends_on = [module.ecs]
}

resource "aws_security_group" "public_alb" {
  name        = "${module.ctx.name_prefix}-pub-alb-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(module.ctx.tags, { Name = "${module.ctx.name_prefix}-pub-alb-sg" })
}

module "alb" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-alb.git"

  context            = module.ctx.context
  lb_name            = "pub"
  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = toset(module.vpc.public_subnets)
  security_groups = [aws_security_group.public_alb.id]

  target_groups = [
    {
      name             = "nginx-tg80"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "ip"
      health_check     = {
        path              = "/"
        healthy_threshold = 2
        protocol          = "HTTP"
        matcher           = "200-302"
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  depends_on = [module.vpc]
}

data "aws_subnet_ids" "was" {
  vpc_id = module.vpc.vpc_id
  filter {
    name   = "tag:Name"
    values = [format("%s-was*", module.ctx.name_prefix)]
  }
  depends_on = [module.vpc]
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-test-service"
  cluster         = module.ecs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.nginx.id
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = module.alb.target_group_arns[0]
  }

  network_configuration {
    assign_public_ip = false
    subnets          = toset(data.aws_subnet_ids.was.ids)
    security_groups  = [aws_security_group.public_alb.id]
  }

  tags = merge(module.ctx.tags, { Name = "nginx-test-service" })

  depends_on = [aws_ecs_task_definition.nginx]
}
```

* [ecs_task_execution_role](./snippet-ecs-task-execution-role.md) 데이터소스 참조