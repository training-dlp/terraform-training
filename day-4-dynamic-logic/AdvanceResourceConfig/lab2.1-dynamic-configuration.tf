# Lab 2.1: Complex Container App with Dynamic Configuration
# This lab demonstrates dynamic blocks for flexible configuration

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables for dynamic configuration
variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment_variables" {
  description = "Dynamic environment variables for the container"
  type = map(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  default = {
    "APP_ENV" = {
      name  = "APP_ENV"
      value = "production"
    }
    "LOG_LEVEL" = {
      name  = "LOG_LEVEL"
      value = "INFO"
    }
    "FEATURE_FLAG_ANALYTICS" = {
      name  = "FEATURE_FLAG_ANALYTICS"
      value = "true"
    }
    "MAX_CONNECTIONS" = {
      name  = "MAX_CONNECTIONS"
      value = "100"
    }
  }
}

variable "secrets" {
  description = "Dynamic secrets configuration"
  type = map(object({
    name  = string
    value = string
  }))
  sensitive = true
  default = {
    "DB_PASSWORD" = {
      name  = "db-password"
      value = "SuperSecretPassword123!"
    }
    "API_KEY" = {
      name  = "api-key"
      value = "sk-1234567890abcdef"
    }
    "JWT_SECRET" = {
      name  = "jwt-secret"
      value = "jwt-secret-key-xyz"
    }
  }
}

variable "volume_mounts" {
  description = "Dynamic volume mount configuration"
  type = map(object({
    name       = string
    mount_path = string
    storage_type = string
    storage_name = optional(string)
  }))
  default = {
    "config" = {
      name         = "config-volume"
      mount_path   = "/etc/config"
      storage_type = "EmptyDir"
    }
    "cache" = {
      name         = "cache-volume"
      mount_path   = "/var/cache"
      storage_type = "EmptyDir"
    }
  }
}

variable "scale_rules" {
  description = "Dynamic scale rules"
  type = map(object({
    name = string
    custom_rule_type = string
    metadata = map(string)
  }))
  default = {
    "http-rule" = {
      name             = "http-scaling"
      custom_rule_type = "http"
      metadata = {
        concurrentRequests = "10"
      }
    }
    "cpu-rule" = {
      name             = "cpu-scaling"
      custom_rule_type = "cpu"
      metadata = {
        type  = "Utilization"
        value = "75"
      }
    }
  }
}

variable "custom_domains" {
  description = "Custom domains for the app"
  type = list(object({
    name          = string
    certificate_id = optional(string)
  }))
  default = []
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-containerapp-dynamic"
  location = var.location
  
  tags = {
    Environment = "Lab"
    Lab         = "2.1"
    Purpose     = "Dynamic Configuration Demo"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-containerapp-dynamic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-dynamic"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Container App with Dynamic Configuration
resource "azurerm_container_app" "dynamic" {
  name                         = "ca-dynamic-config"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  # Dynamic secrets block
  dynamic "secret" {
    for_each = var.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }
  
  template {
    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
      
      # Dynamic environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
      
      # Environment variables referencing secrets
      dynamic "env" {
        for_each = var.secrets
        content {
          name        = upper(replace(env.key, "-", "_"))
          secret_name = env.value.name
        }
      }
      
      # Dynamic volume mounts
      dynamic "volume_mounts" {
        for_each = var.volume_mounts
        content {
          name = volume_mounts.value.name
          path = volume_mounts.value.mount_path
        }
      }
    }
    
    # Dynamic volumes
    dynamic "volume" {
      for_each = var.volume_mounts
      content {
        name         = volume.value.name
        storage_type = volume.value.storage_type
        storage_name = volume.value.storage_name
      }
    }
    
    min_replicas = 1
    max_replicas = 10
  }
  
  # Ingress configuration
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
    
    # Dynamic custom domains
    dynamic "custom_domain" {
      for_each = var.custom_domains
      content {
        name           = custom_domain.value.name
        certificate_id = custom_domain.value.certificate_id
      }
    }
  }
  
  tags = {
    Lab = "2.1"
    ConfigType = "Dynamic"
  }
}

# Container App with Dynamic Scaling Rules
resource "azurerm_container_app" "dynamic_scaling" {
  name                         = "ca-dynamic-scaling"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
    
    min_replicas = 0
    max_replicas = 10
    
    # Dynamic scale rules
    dynamic "custom_scale_rule" {
      for_each = var.scale_rules
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.custom_rule_type
        metadata         = custom_scale_rule.value.metadata
      }
    }
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Advanced example: Container App with conditional configuration
resource "azurerm_container_app" "advanced" {
  name                         = "ca-advanced-dynamic"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Multiple"
  
  template {
    # Multiple containers with dynamic configuration
    dynamic "container" {
      for_each = {
        "frontend" = {
          image  = "nginx:alpine"
          cpu    = 0.25
          memory = "0.5Gi"
          port   = 80
        }
        "sidecar" = {
          image  = "busybox:latest"
          cpu    = 0.25
          memory = "0.5Gi"
          port   = 8080
        }
      }
      content {
        name   = container.key
        image  = container.value.image
        cpu    = container.value.cpu
        memory = container.value.memory
        
        # Add port only if it exists
        dynamic "liveness_probe" {
          for_each = container.key == "frontend" ? [1] : []
          content {
            transport = "HTTP"
            port      = 80
            path      = "/health"
          }
        }
      }
    }
    
    min_replicas = 1
    max_replicas = 5
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# Outputs
output "dynamic_app_url" {
  description = "URL of the dynamic configuration app"
  value       = "https://${azurerm_container_app.dynamic.ingress[0].fqdn}"
}

output "dynamic_scaling_app_url" {
  description = "URL of the dynamic scaling app"
  value       = "https://${azurerm_container_app.dynamic_scaling.ingress[0].fqdn}"
}

output "advanced_app_url" {
  description = "URL of the advanced dynamic app"
  value       = "https://${azurerm_container_app.advanced.ingress[0].fqdn}"
}

output "configured_secrets" {
  description = "List of configured secrets"
  value       = [for s in var.secrets : s.name]
}

output "configured_env_vars" {
  description = "List of configured environment variables"
  value       = [for e in var.environment_variables : e.name]
}

output "configured_volumes" {
  description = "List of configured volumes"
  value       = [for v in var.volume_mounts : "${v.name} -> ${v.mount_path}"]
}

output "lab_summary" {
  description = "Lab summary and key learnings"
  value = <<-EOT
    
    LAB 2.1 COMPLETED
    =================
    
    Dynamic Blocks Demonstrated:
    - ${length(var.secrets)} secrets configured dynamically
    - ${length(var.environment_variables)} environment variables
    - ${length(var.volume_mounts)} volume mounts
    - ${length(var.scale_rules)} scale rules
    
    Key Learnings:
    1. Dynamic blocks reduce code duplication
    2. for_each enables flexible configuration
    3. Conditional blocks with count/for_each
    4. Complex nested dynamic blocks
    
    Test the deployment:
    - Dynamic Config App: ${azurerm_container_app.dynamic.ingress[0].fqdn}
    - Dynamic Scaling App: ${azurerm_container_app.dynamic_scaling.ingress[0].fqdn}
    - Advanced Multi-Container: ${azurerm_container_app.advanced.ingress[0].fqdn}
    
  EOT
}
