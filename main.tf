locals {
  cluster_name = var.middle_name == null ? "${var.context.name_prefix}-ecs" : "${var.context.name_prefix}-${var.middle_name}-ecs"
}

resource "aws_ecs_cluster" "this" {
  count = var.create_ecs ? 1 : 0

  name = local.cluster_name

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    iterator = strategy

    content {
      capacity_provider = strategy.value["capacity_provider"]
      weight            = lookup(strategy.value, "weight", null)
      base              = lookup(strategy.value, "base", null)
    }
  }

  setting {
    name  = "containerInsights"
    value = var.container_insights ? "enabled" : "disabled"
  }

  tags = merge(var.context.tags, { Name = local.cluster_name })
}