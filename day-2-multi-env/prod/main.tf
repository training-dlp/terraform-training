terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
  
  backend "azurerm" {
    # Configuration provided via backend.hcl
  }
}

provider "azurerm" {
  features {}
}

locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Workshop    = "Day-2-Multi-Env"
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}-${var.location}"
  location = var.location
  tags     = local.common_tags
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "app_insights" {
  name                = "appi-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.logs.id
  application_type    = "web"
  tags                = local.common_tags
}

# Container App Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "cae-${local.resource_prefix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
  tags                       = local.common_tags
}

# Container App
resource "azurerm_container_app" "app" {
  name                         = "ca-${local.resource_prefix}"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  template {
    container {
      name   = "workshop-app"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "APP_NAME"
        value = "Terraform Workshop - ${upper(var.environment)}"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name  = "APPINSIGHTS_INSTRUMENTATIONKEY"
        value = azurerm_application_insights.app_insights.instrumentation_key
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# Storage Account (environment-specific)
resource "azurerm_storage_account" "data" {
  name                     = replace("st${local.resource_prefix}", "-", "")
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  
  tags = local.common_tags
}
