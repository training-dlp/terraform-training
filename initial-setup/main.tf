terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Local values for common tags and naming
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Workshop    = "Terraform-Advanced"
  }
  
  resource_prefix = "${var.project_name}-${var.environment}"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${local.resource_prefix}"
  location = var.location
  tags     = local.common_tags
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = replace("acr${local.resource_prefix}", "-", "")
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.common_tags
}

# Log Analytics Workspace for Container App
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "log-${local.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
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
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "APP_NAME"
        value = "Terraform Workshop"
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

    min_replicas = 1
    max_replicas = 3
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

# Null resource to build and push Docker image (optional - for custom image)
resource "null_resource" "docker_build" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Docker build would happen here"
      echo "ACR Login Server: ${azurerm_container_registry.acr.login_server}"
      echo "To build and push your custom image, run:"
      echo "az acr build --registry ${azurerm_container_registry.acr.name} --image workshop-app:v1 ./app"
    EOT
  }

  depends_on = [azurerm_container_registry.acr]
}
