# Lab 3.1: Container App Module - Main Configuration
# File: modules/container-app/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Validate that max_replicas is greater than min_replicas
locals {
  validate_replicas = var.max_replicas >= var.min_replicas ? true : file("ERROR: max_replicas must be >= min_replicas")
  
  # Ensure Dapr config is provided if Dapr is enabled
  validate_dapr = var.dapr_enabled ? (
    var.dapr_app_id != "" ? true : file("ERROR: dapr_app_id is required when dapr_enabled is true")
  ) : true
  
  # Common tags
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "container-app"
  }
  
  merged_tags = merge(local.default_tags, var.tags)
}

# Container App
resource "azurerm_container_app" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  
  # Registry configuration (if provided)
  dynamic "registry" {
    for_each = var.registry_server != "" ? [1] : []
    content {
      server               = var.registry_server
      username             = var.registry_username
      password_secret_name = "registry-password"
    }
  }
  
  # Secrets
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }
  
  # Add registry password as secret if registry is configured
  dynamic "secret" {
    for_each = var.registry_server != "" && var.registry_password != "" ? [1] : []
    content {
      name  = "registry-password"
      value = var.registry_password
    }
  }
  
  # Dapr configuration
  dynamic "dapr" {
    for_each = var.dapr_enabled ? [1] : []
    content {
      app_id       = var.dapr_app_id
      app_protocol = "http"
      app_port     = var.dapr_app_port
    }
  }
  
  template {
    container {
      name   = var.container_name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory
      
      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
      
      # Liveness probe
      dynamic "liveness_probe" {
        for_each = var.enable_health_probes ? [1] : []
        content {
          transport             = "HTTP"
          port                  = var.target_port
          path                  = var.health_check_path
          initial_delay_seconds = 5
          interval_seconds      = 10
          timeout_seconds       = 3
          failure_threshold     = 3
        }
      }
      
      # Readiness probe
      dynamic "readiness_probe" {
        for_each = var.enable_health_probes ? [1] : []
        content {
          transport             = "HTTP"
          port                  = var.target_port
          path                  = var.health_check_path
          initial_delay_seconds = 3
          interval_seconds      = 5
          timeout_seconds       = 2
          failure_threshold     = 3
        }
      }
    }
    
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
    
    # HTTP scaling rule
    dynamic "http_scale_rule" {
      for_each = var.enable_http_scale_rule ? [1] : []
      content {
        name                = "http-scale-${var.name}"
        concurrent_requests = var.http_concurrent_requests
      }
    }
  }
  
  # Ingress configuration
  dynamic "ingress" {
    for_each = var.ingress_enabled ? [1] : []
    content {
      external_enabled = var.external_enabled
      target_port      = var.target_port
      
      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }
  
  tags = local.merged_tags
}
