variable "create" {
  description = "Controls if ECS should be created"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "The cluster name of ECS Cluster. if not set automatically generate it."
  type        = string
  default     = null
}

variable "capacity_providers" {
  description = "List of short names of one or more capacity providers to associate with the cluster. Valid values also include FARGATE and FARGATE_SPOT."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "The capacity provider strategy to use by default for the cluster. Can be one or more."
  type        = list(map(any))
  default     = [
    {
      capacity_provider = "FARGATE"
      weight            = 1
    }
  ]
}

variable "container_insights" {
  description = "Controls if ECS Cluster has container insights enabled"
  type        = bool
  default     = true
}

variable "create_ecs_task_execution_role" {
  description = "Whether to create ECS task-execution-role."
  type        = bool
  default     = true
}

variable "ecs_task_role_name" {
  description = "Whether to create task-execution-role for this ECS Cluster. if not set automatically generate it."
  type        = string
  default     = null
}

###

variable "kms_key_id" {
  description = "The AWS Key Management Service key ID (KMS_ARN) to encrypt the data between the local client and the container."
  type        = string
  default     = null
}

variable "execute_command_configuration" {
  type = object({
    kms_key_id = optional(string)
    logging    = string
  })
  default     = null
  description = <<EOF
The log setting to use for redirecting logs for your execute command results
see - https://docs.aws.amazon.com/ko_kr/AmazonECS/latest/developerguide/ecs-exec.html#ecs-exec-architecture
see - https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-ecs-cluster-executecommandconfiguration.html
see - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster#execute_command_configuration

    execute_command_configuration = {
      logging    = "DEFAULT" # Valid values are NONE, DEFAULT and OVERRIDE.
      log_configuration = {
        s3_bucket_name                 = null     # The name of the S3 bucket to send logs to.
        s3_key_prefix                  = null     # An optional folder in the S3 bucket to place logs in.
        s3_bucket_encryption_enabled   = null     # Whether or not to enable encryption on the logs sent to S3.
      }
    }
EOF
}

variable "create_cloudwatch_log_group" {
  description = "Whether to create cloudwatch_log_group for execute commands."
  type        = bool
  default     = false
}

variable "retention_in_days" {
  description = "cloudwatch log group retention_in_days"
  type        = number
  default     = 90
}

variable "enable_s3_bucket_log" {
  description = "Whether to enable s3_bucket log for execute commands."
  type        = bool
  default     = false
}

###############################################################################
# Capacity Providers
###############################################################################

variable "default_capacity_provider_use_fargate" {
  description = "Determines whether to use Fargate or autoscaling for default capacity provider strategy"
  type        = bool
  default     = true
}

variable "fargate_capacity_providers" {
  type        = any
  default     = {}
  description = <<EOF
Map of Fargate capacity provider definitions to use for the cluster"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base = null       # Optional - The number of tasks, at a minimum, to run on the specified capacity provider.
        weight = 50       # Optional - The relative percentage of the total number of launched tasks that should use the specified capacity provider.
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
EOF

}

variable "autoscaling_capacity_providers" {
  type        = any
  default     = {}
  description = <<EOF
Map of autoscaling capacity provider definitions to create for the cluster

  autoscaling_capacity_providers = {
    one = {
      default_capacity_provider_strategy = {
        base   = 10
        weight = 60
      }
      auto_scaling_group_arn         = "<asg_one_arn>"
      managed_termination_protection = "ENABLED"
      managed_scaling = {
        maximum_scaling_step_size = 5
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 60
      }
    }
    two = {
      default_capacity_provider_strategy = {
        weight = 40
      }
      auto_scaling_group_arn         = "<asg_two_arn>"
      managed_termination_protection = "ENABLED"
      managed_scaling = {
        maximum_scaling_step_size = 15
        minimum_scaling_step_size = 5
        status                    = "ENABLED"
        target_capacity           = 90
      }

    }
  }
EOF
}
