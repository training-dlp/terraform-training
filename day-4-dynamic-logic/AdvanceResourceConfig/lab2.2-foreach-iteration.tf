# Lab 2.2: Multi-Container Apps with for_each
# This lab demonstrates for_each for creating multiple similar resources

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

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# Complex map defining multiple container apps
variable "container_apps" {
  description = "Map of container applications to deploy"
  type = map(object({
    image              = string
    cpu                = number
    memory             = string
    min_replicas       = number
    max_replicas       = number
    target_port        = number
    external_enabled   = bool
    environment_vars   = map(string)
    revision_mode      = string
    health_check_path  = optional(string, "/health")
    enable_dapr        = optional(bool, false)
    dapr_app_id        = optional(string)
    dapr_app_port      = optional(number)
  }))
  
  default = {
    "frontend" = {
      image              = "nginx:alpine"
      cpu                = 0.5
      memory             = "1Gi"
      min_replicas       = 2
      max_replicas       = 10
      target_port        = 80
      external_enabled   = true
      revision_mode      = "Single"
      health_check_path  = "/"
      environment_vars = {
        APP_NAME    = "Frontend"
        APP_VERSION = "1.0.0"
        BACKEND_URL = "http://backend"
      }
    }
    
    "backend" = {
      image              = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu                = 0.5
      memory             = "1Gi"
      min_replicas       = 2
      max_replicas       = 8
      target_port        = 80
      external_enabled   = true
      revision_mode      = "Single"
      health_check_path  = "/api/health"
      environment_vars = {
        APP_NAME      = "Backend"
        APP_VERSION   = "1.0.0"
        DATABASE_URL  = "postgresql://db:5432"
        CACHE_ENABLED = "true"
      }
    }
    
    "api-gateway" = {
      image              = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu                = 0.25
      memory             = "0.5Gi"
      min_replicas       = 1
      max_replicas       = 5
      target_port        = 80
      external_enabled   = true
      revision_mode      = "Single"
      health_check_path  = "/health"
      environment_vars = {
        APP_NAME     = "API Gateway"
        APP_VERSION  = "1.0.0"
        RATE_LIMIT   = "1000"
      }
    }
    
    "worker" = {
      image              = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu                = 1.0
      memory             = "2Gi"
      min_replicas       = 1
      max_replicas       = 3
      target_port        = 80
      external_enabled   = false
      revision_mode      = "Single"
      environment_vars = {
        APP_NAME       = "Background Worker"
        APP_VERSION    = "1.0.0"
        QUEUE_URL      = "https://queue.service"
        WORKER_THREADS = "4"
      }
    }
  }
}

# Microservices with Dapr enabled
variable "dapr_apps" {
  description = "Dapr-enabled microservices"
  type = map(object({
    image         = string
    cpu           = number
    memory        = string
    min_replicas  = number
    max_replicas  = number
    target_port   = number
    dapr_app_port = number
  }))
  
  default = {
    "orders-service" = {
      image         = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu           = 0.5
      memory        = "1Gi"
      min_replicas  = 2
      max_replicas  = 5
      target_port   = 80
      dapr_app_port = 3000
    }
    
    "inventory-service" = {
      image         = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu           = 0.5
      memory        = "1Gi"
      min_replicas  = 2
      max_replicas  = 5
      target_port   = 80
      dapr_app_port = 3001
    }
    
    "payment-service" = {
      image         = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu           = 0.5
      memory        = "1Gi"
      min_replicas  = 3
      max_replicas  = 8
      target_port   = 80
      dapr_app_port = 3002
    }
  }
}

# Shared infrastructure
resource "azurerm_resource_group" "main" {
  name     = "rg-containerapp-foreach"
  location = var.location
  
  tags = {
    Lab     = "2.2"
    Purpose = "for_each demonstration"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-containerapp-foreach"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-foreach"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  # Enable Dapr for microservices
  dapr_application_insights_connection_string = azurerm_application_insights.main.connection_string
}

# Application Insights for Dapr
resource "azurerm_application_insights" "main" {
  name                = "appi-containerapp-foreach"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

# Create multiple container apps using for_each
resource "azurerm_container_app" "apps" {
  for_each = var.container_apps
  
  name                         = "ca-${each.key}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = each.value.revision_mode
  
  template {
    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory
      
      # Dynamic environment variables using for_each
      dynamic "env" {
        for_each = each.value.environment_vars
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Add service discovery environment variable
      env {
        name  = "SERVICE_NAME"
        value = each.key
      }
      
      # Liveness probe
      liveness_probe {
        transport = "HTTP"
        port      = each.value.target_port
        path      = each.value.health_check_path
        
        initial_delay_seconds = 5
        interval_seconds      = 10
        timeout_seconds       = 3
        failure_threshold     = 3
      }
      
      # Readiness probe
      readiness_probe {
        transport = "HTTP"
        port      = each.value.target_port
        path      = each.value.health_check_path
        
        initial_delay_seconds = 3
        interval_seconds      = 5
        timeout_seconds       = 2
        failure_threshold     = 3
      }
    }
    
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas
    
    # HTTP scaling rule
    http_scale_rule {
      name                = "http-${each.key}"
      concurrent_requests = 10
    }
  }
  
  # Conditional ingress - only if external_enabled is true
  dynamic "ingress" {
    for_each = each.value.external_enabled ? [1] : []
    content {
      external_enabled = true
      target_port      = each.value.target_port
      
      traffic_weight {
        latest_revision = true
        percentage      = 100
      }
    }
  }
  
  tags = {
    Service     = each.key
    Managed     = "Terraform"
    Environment = "Lab"
  }
}

# Create Dapr-enabled microservices
resource "azurerm_container_app" "dapr_apps" {
  for_each = var.dapr_apps
  
  name                         = "ca-dapr-${each.key}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  # Enable Dapr
  dapr {
    app_id       = each.key
    app_protocol = "http"
    app_port     = each.value.dapr_app_port
  }
  
  template {
    container {
      name   = each.key
      image  = each.value.image
      cpu    = each.value.cpu
      memory = each.value.memory
      
      env {
        name  = "APP_PORT"
        value = tostring(each.value.dapr_app_port)
      }
      
      env {
        name  = "DAPR_APP_ID"
        value = each.key
      }
    }
    
    min_replicas = each.value.min_replicas
    max_replicas = each.value.max_replicas
  }
  
  ingress {
    external_enabled = true
    target_port      = each.value.target_port
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = {
    Service     = each.key
    Dapr        = "enabled"
    Type        = "microservice"
  }
}

# Create Azure Container Registry (optional, for custom images)
resource "azurerm_container_registry" "main" {
  name                = "acrcontainerapp${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Outputs using for expressions
output "app_urls" {
  description = "URLs of all deployed applications"
  value = {
    for k, v in azurerm_container_app.apps : 
    k => v.ingress != null && length(v.ingress) > 0 ? "https://${v.ingress[0].fqdn}" : "Internal service (no external URL)"
  }
}

output "dapr_app_urls" {
  description = "URLs of all Dapr-enabled applications"
  value = {
    for k, v in azurerm_container_app.dapr_apps : 
    k => "https://${v.ingress[0].fqdn}"
  }
}

output "app_configurations" {
  description = "Configuration summary of all apps"
  value = {
    for k, v in var.container_apps :
    k => {
      replicas = "${v.min_replicas}-${v.max_replicas}"
      resources = "${v.cpu} CPU, ${v.memory}"
      external = v.external_enabled
    }
  }
}

output "total_apps_deployed" {
  description = "Total number of container apps deployed"
  value       = length(azurerm_container_app.apps) + length(azurerm_container_app.dapr_apps)
}

output "container_registry" {
  description = "Container Registry details"
  value = {
    name          = azurerm_container_registry.main.name
    login_server  = azurerm_container_registry.main.login_server
    admin_username = azurerm_container_registry.main.admin_username
  }
}

output "container_registry_password" {
  description = "Container Registry admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "lab_summary" {
  description = "Lab completion summary"
  value = <<-EOT
    
    LAB 2.2 COMPLETED
    =================
    
    Resources Created with for_each:
    - ${length(var.container_apps)} standard container apps
    - ${length(var.dapr_apps)} Dapr-enabled microservices
    - 1 shared Container App Environment
    - 1 Log Analytics Workspace
    - 1 Container Registry
    
    Total Container Apps: ${length(azurerm_container_app.apps) + length(azurerm_container_app.dapr_apps)}
    
    Key Concepts Demonstrated:
    1. for_each with complex object maps
    2. Conditional resource creation (ingress)
    3. Dynamic blocks within for_each
    4. for expressions in outputs
    5. Resource references across for_each
    
    Standard Apps:
    ${join("\n    ", [for k, v in azurerm_container_app.apps : "- ${k}: ${v.ingress != null && length(v.ingress) > 0 ? v.ingress[0].fqdn : "internal"}"])}
    
    Dapr Microservices:
    ${join("\n    ", [for k, v in azurerm_container_app.dapr_apps : "- ${k}: ${v.ingress[0].fqdn}"])}
    
    Next Steps:
    1. Test inter-service communication
    2. Scale individual services
    3. Update configurations per service
    4. Add/remove services by updating the map
    
  EOT
}
