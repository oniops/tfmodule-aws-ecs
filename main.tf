locals {
  name_prefix                 = var.context.name_prefix
  tags                        = var.context.tags
  cluster_name                = var.cluster_name == null ? "${local.name_prefix}-ecs" : var.cluster_name
  log_group_name              = "/aws/ecs/${local.cluster_name}"
  create_cloudwatch_log_group = var.create_cloudwatch_log_group && var.execute_command_configuration != null ? true : false
  enable_s3_bucket_log        = local.create_cloudwatch_log_group ? false : var.enable_s3_bucket_log
}

resource "aws_cloudwatch_log_group" "this" {
  count             = local.create_cloudwatch_log_group ? 1 : 0
  name              = local.log_group_name
  kms_key_id        = var.kms_key_id
  retention_in_days = var.retention_in_days
  tags              = merge(local.tags, {
    Name = local.log_group_name
  })
}

resource "aws_ecs_cluster" "this" {
  count = var.create ? 1 : 0
  name  = local.cluster_name

  dynamic "configuration" {
    for_each = local.create_cloudwatch_log_group ? [true] : []
    content {
      execute_command_configuration {
        kms_key_id = var.kms_key_id
        logging    = try(var.execute_command_configuration["logging"], null)

        log_configuration {
          cloud_watch_encryption_enabled = var.kms_key_id != null ? true : false
          cloud_watch_log_group_name     = try(aws_cloudwatch_log_group.this[0].name, null)
        }
      }
    }
  }

  dynamic "configuration" {
    for_each = local.enable_s3_bucket_log ? [true] : []
    content {
      execute_command_configuration {
        kms_key_id = var.kms_key_id
        logging    = try(var.execute_command_configuration["logging"], null)

        log_configuration {
          s3_bucket_name               = try(var.execute_command_configuration["log_configuration"]["s3_bucket_name"], null)
          s3_key_prefix                = try(var.execute_command_configuration["log_configuration"]["s3_key_prefix"], null)
          s3_bucket_encryption_enabled = try(var.execute_command_configuration["log_configuration"]["s3_bucket_encryption_enabled"], null)
        }
      }
    }
  }

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(local.tags, {
    Name = local.cluster_name
  })
}
