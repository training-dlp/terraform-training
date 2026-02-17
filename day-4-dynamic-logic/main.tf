terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables with validation
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
  
  validation {
    condition     = can(regex("^(east|west|central|north|south)", var.location))
    error_message = "Location must be a valid Azure region."
  }
}

variable "enable_monitoring" {
  description = "Enable advanced monitoring"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Enable backup"
  type        = bool
  default     = false
}

variable "container_names" {
  description = "List of storage containers to create"
  type        = list(string)
  default     = ["data", "logs", "backups"]
}

variable "scaling_rules" {
  description = "Dynamic scaling rules"
  type = list(object({
    name           = string
    metric_name    = string
    metric_trigger = number
  }))
  default = [
    {
      name           = "cpu-scaling"
      metric_name    = "cpu"
      metric_trigger = 80
    },
    {
      name           = "memory-scaling"
      metric_name    = "memory"
      metric_trigger = 75
    }
  ]
}

variable "environment_variables" {
  description = "Environment variables for container"
  type        = map(string)
  default = {
    APP_ENV     = "production"
    LOG_LEVEL   = "info"
    ENABLE_CACHE = "true"
  }
}

# Locals with conditional logic
locals {
  prefix = "day4-${var.environment}"
  
  # Environment-specific configuration
  config = {
    dev = {
      cpu          = 0.25
      memory       = "0.5Gi"
      replicas_min = 1
      replicas_max = 2
      backup_enabled = false
      monitoring_level = "basic"
    }
    staging = {
      cpu          = 0.5
      memory       = "1Gi"
      replicas_min = 2
      replicas_max = 4
      backup_enabled = true
      monitoring_level = "standard"
    }
    prod = {
      cpu          = 1.0
      memory       = "2Gi"
      replicas_min = 3
      replicas_max = 10
      backup_enabled = true
      monitoring_level = "advanced"
    }
  }
  
  # Select configuration based on environment
  selected_config = local.config[var.environment]
  
  # Conditional tags
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Workshop    = "Day-4-Dynamic"
    },
    var.environment == "prod" ? {
      Criticality = "High"
      SLA         = "99.9"
    } : {}
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.common_tags
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = replace("st${local.prefix}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.environment == "prod" ? "Premium" : "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  
  tags = local.common_tags
}

# Dynamic Containers using for_each
resource "azurerm_storage_container" "containers" {
  for_each = toset(var.container_names)
  
  name                  = each.value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  
  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  
  tags = local.common_tags
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  tags = local.common_tags
}

# Container App with dynamic blocks
resource "azurerm_container_app" "main" {
  name                         = "ca-${local.prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  template {
    container {
      name   = "app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = local.selected_config.cpu
      memory = local.selected_config.memory

      # Dynamic environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }
      
      # Additional env vars based on conditions
      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }
      
      env {
        name  = "MONITORING_LEVEL"
        value = local.selected_config.monitoring_level
      }
    }

    min_replicas = local.selected_config.replicas_min
    max_replicas = local.selected_config.replicas_max
  }

  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Conditional secrets (only for prod)
  dynamic "secret" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      name  = "db-connection"
      value = "secret-value-here"
    }
  }
}

# Conditional monitoring alert (only if enabled)
resource "azurerm_monitor_action_group" "alerts" {
  count               = var.enable_monitoring ? 1 : 0
  name                = "ag-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "alerts"
  
  email_receiver {
    name          = "admin"
    email_address = "admin@example.com"
  }
  
  tags = local.common_tags
}

# Conditional backup (only if enabled)
resource "azurerm_recovery_services_vault" "backup" {
  count               = var.enable_backup || local.selected_config.backup_enabled ? 1 : 0
  name                = "rsv-${local.prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  
  tags = local.common_tags
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "app_url" {
  value = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "selected_config" {
  value = local.selected_config
}

output "created_containers" {
  value = keys(azurerm_storage_container.containers)
}

output "monitoring_enabled" {
  value = var.enable_monitoring
}

output "backup_enabled" {
  value = var.enable_backup || local.selected_config.backup_enabled
}
