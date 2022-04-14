# tfmodule-aws-ecs

AWS ECS 컨테이너 오케스트레이션 서비스를 구성 하는 테라폼 모듈 입니다.

## [ECS](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/Welcome.html)
ECS 는 AWS 의 다양한 서비스(기능)들과 통합과 빠르고 쉽게 구성이 가능합니다.

컨테이너 오케스트레이션 도구로는 AWS 이외에도 Docker Swarm, Kubernetes, 하시코프의 Nomad 등 오픈소스가 있습니다.

## Usage

```
module "ecs" {
  source = "git::https://code.bespinglobal.com/scm/op/tfmodule-aws-ecs.git"
  
  context = module.ctx.context
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  container_insights = true

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
    }
  ]
}

module "ctx" {
  source = "git::https://github.com/bsp-dx/edu-terraform-aws.git?ref=tfmodule-context-..."
  context = {  
    # ... You need to define context variables ...
  }
}
```

### Example
- [ECS Fargate 클러스터 구성 참고](./docs/snippet-ecs-fargate.md)
- [ECS EC2 클러스터 구성 참고](./docs/snippet-ecs-ec2.md)
- [ECS Task Execution Role 구성 참고](./docs/snippet-ecs-task-execution-role.md)


## ECS Architecture
ECS 아키텍처를 구성하는 주요 컴포넌트 관계와 그 역할을 이해 합니다.

[AWS ECS Components](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/welcome-features.html)

### ECS Cluster
Amazon ECS 클러스터는 태스크 또는 서비스의 논리적 그룹입니다.  
태스크와 서비스는 클러스터에 등록된 인프라에서 실행 되며 인프라 용량은 AWS Fargate 또는 Amazon EC2 인스턴스가 있습니다.

### ECS Task Definition
Docker 컨테이너를 실행하기 위해 정의한 세트 입니다.  
컨테이너의 이미지, CPU / 메모리 리소스 할당, Port 매핑, Volume 등의 설정이 있으며 docker run 명령에서 가능했던 대부분 옵션이 설정을 할 수 있습니다.

### ECS Task
ECS Task Definition 으로 배포된 Container Set 을 Task 라고 합니다.   
ECS Cluster 에 속한 Container instance 에 배포 되며 배포된 최소 인스턴스 단위를 Task 입니다.
Task 에는 Container 를 한개만 포함 할 수도 있고, 다수의 Container 를 포함할 수도 있습니다.

### ECS Service
Task 들의 Life cycle 을 관리하는 부분을 Service 라고 합니다.  
ECS Cluster 에 Task 를 몇개나 배포 할 것인지 결정 하고, 실제 Task 들을 외부에 서비스 하기 위해 ELB 에 연결 할 수도 있습니다.  
만약 실행 중인 Task 가 어떤 이유로 작동이 중지 되면 이것을 자동으로 감지하여 새로운 Task 를 Cluster 에 배포 하는 고 가용성에 대한 정책도 Service 에서 관리 합니다.


### [Fargate 시작 유형](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/launch_types.html)

Fargate 시작 유형은 프로비저닝 없이 컨테이너화된 애플리케이션을 실행하고 백엔드 인프라를 관리할 때 사용할 수 있습니다. AWS Fargate은 서버리스 방식으로 Amazon ECS 워크로드를 호스팅할 수 있습니다.

![ECS Fargate](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/images/overview-fargate.png)


### [EC2 시작 유형](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/launch_types.html)

EC2 시작 유형은 Amazon ECS 클러스터를 등록하고 직접 관리하는 Amazon EC2 인스턴스에서 컨테이너화된 애플리케이션을 실행하는 데 사용할 수 있습니다.

![ECS EC2](https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/images/overview-standard.png)


## Input Variables

| Name | Description | Type | Example | Required |
|------|-------------|------|---------|:--------:|
| capacity_providers | capacity providers 는 작업 및 서비스를 실행하는 데 필요한 가용성, 확장성 및 비용을 개선합니다. 유효한 capacity provider 는 FARGATE 및 FARGATE_SPOT 입니다. | list(string) | ["FARGATE", "FARGATE_SPOT"] | No |
| default_capacity_provider_strategy | 클러스터에 기본적으로 사용할 capacity_providers 전략입니다. | list(map(any)) | {} | No |
| enable_lifecycle_policy | 리포지토리에 수명 주기 정책의 추가 여부를 설정 합니다. | bool | false| No |
| scan_images_on_push | 이미지가 저장소로 푸시된 후 스캔 여부를 설정 합니다. | bool | true| No |
| principals_full     | ECR 저장소의 전체 액세스 권한을 가지는 IAM 리소스 ARN 입니다. | list(string) | ["arn:aws:iam::111111:user/apple_arn", "arn:aws:iam::111111:role/admin_arn"] | No |
| principals_readonly | ECR 저장소의 읽기 전용 IAM 리소스 ARN 입니다. | list(string) | ["*"] | No |
| tags | ECR 저장소의 태그 속성을 정의 합니다. | obejct({}) | <pre>{<br>    Project = "simple"<br>    Environment = "Test"<br>    Team = "DX"<br>    Owner = "symplesims@email.com"<br>}</pre> | Yes |
| name | ECS 클러스터 이름을 정의 합니다. | string | - | No |
| container_insights | ECS 클러스터의 컨테이너 정보를 식별하기 위해 CloudWatch 로그 그룹에 적재 할지 여부입니다. | bool | false | No |
| middle_name | ECS 클러스터의 중간 이름을 설정 합니다. (여러개의 ECS 클러스터를 구성 할 때 정의 합니다.) | string | - | No |
| create_ecs_task_execution_role | 프로젝트를 위한 별도의 ECS 작업 실행 역할을 생성할지 여부입니다. (Region 에서 관리하는 것을 권장합니다.) | bool | false | No |
| context | 프로젝트에 관한 리소스를 생성 및 관리에 참조 되는 정보로 표준화된 네이밍 정책 및 리소스를 위한 속성 정보를 포함하며 이를 통해 데이터 소스 참조에도 활용됩니다. | object({}) | - | Yes |
| __________________________________ | ______________________________________________________ | ___ | ___ | ___ |


## Output Values

| Name | Description | 
|------|-------------|
| ecs_cluster_id  | ID of the ECS Cluster |
| ecs_cluster_arn | ARN of the ECS Cluster | 
| ecs_cluster_name| The name of the ECS cluster | 
| ecs_task_execution_role_arn| The ARN of ECS task execution role | 

