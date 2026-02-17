# Lab 1.2: Multi-Environment Container Apps with Workspaces
# This lab demonstrates using Terraform workspaces for environment isolation

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  # Backend configuration (created in Lab 1.1)
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "tfstatedev12345678" # Replace with your storage account
    container_name       = "tfstate"
    key                  = "container-apps.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Locals for workspace-specific configuration
locals {
  # Get current workspace name
  workspace = terraform.workspace
  
  # Environment-specific configurations
  env_config = {
    dev = {
      location              = "eastus"
      container_cpu         = 0.25
      container_memory      = "0.5Gi"
      min_replicas          = 1
      max_replicas          = 2
      instance_count        = 1
    }
    staging = {
      location              = "eastus"
      container_cpu         = 0.5
      container_memory      = "1Gi"
      min_replicas          = 2
      max_replicas          = 5
      instance_count        = 2
    }
    prod = {
      location              = "eastus2" # Different region for prod
      container_cpu         = 1.0
      container_memory      = "2Gi"
      min_replicas          = 3
      max_replicas          = 10
      instance_count        = 3
    }
  }
  
  # Get current environment config
  current_env = local.env_config[local.workspace]
  
  # Common tags
  common_tags = {
    Environment = local.workspace
    ManagedBy   = "Terraform"
    Workspace   = local.workspace
    CostCenter  = "Engineering"
  }
}

# Resource Group - workspace-specific
resource "azurerm_resource_group" "container_app" {
  name     = "rg-containerapp-${local.workspace}"
  location = local.current_env.location
  tags     = local.common_tags
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "container_app" {
  name                = "log-containerapp-${local.workspace}"
  location            = azurerm_resource_group.container_app.location
  resource_group_name = azurerm_resource_group.container_app.name
  sku                 = "PerGB2018"
  retention_in_days   = local.workspace == "prod" ? 90 : 30
  tags                = local.common_tags
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${local.workspace}"
  location                   = azurerm_resource_group.container_app.location
  resource_group_name        = azurerm_resource_group.container_app.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.container_app.id
  
  tags = local.common_tags
}

# Container App - Web Application
resource "azurerm_container_app" "web" {
  name                         = "ca-webapp-${local.workspace}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.container_app.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "webapp"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = local.current_env.container_cpu
      memory = local.current_env.container_memory
      
      env {
        name  = "ENVIRONMENT"
        value = local.workspace
      }
      
      env {
        name  = "APP_VERSION"
        value = "1.0.0"
      }
      
      env {
        name  = "WORKSPACE"
        value = terraform.workspace
      }
    }
    
    min_replicas = local.current_env.min_replicas
    max_replicas = local.current_env.max_replicas
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Application = "WebApp"
    }
  )
}

# Container App - API Backend
resource "azurerm_container_app" "api" {
  name                         = "ca-api-${local.workspace}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.container_app.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = local.current_env.container_cpu
      memory = local.current_env.container_memory
      
      env {
        name  = "ENVIRONMENT"
        value = local.workspace
      }
      
      env {
        name  = "API_VERSION"
        value = "v1"
      }
      
      env {
        name  = "LOG_LEVEL"
        value = local.workspace == "prod" ? "INFO" : "DEBUG"
      }
    }
    
    min_replicas = local.current_env.min_replicas
    max_replicas = local.current_env.max_replicas
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = merge(
    local.common_tags,
    {
      Application = "API"
    }
  )
}

# Outputs
output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "environment_config" {
  description = "Configuration for current environment"
  value       = local.current_env
}

output "webapp_url" {
  description = "Web application URL"
  value       = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}

output "api_url" {
  description = "API URL"
  value       = "https://${azurerm_container_app.api.ingress[0].fqdn}"
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.container_app.name
}

# Lab Instructions
output "lab_instructions" {
  description = "Instructions for completing the lab"
  value = <<-EOT
    
    LAB 1.2: WORKSPACE COMMANDS
    ===========================
    
    1. List all workspaces:
       terraform workspace list
    
    2. Create and switch to dev workspace:
       terraform workspace new dev
       terraform plan
       terraform apply
    
    3. Create and switch to staging workspace:
       terraform workspace new staging
       terraform plan
       terraform apply
    
    4. Create and switch to prod workspace:
       terraform workspace new prod
       terraform plan
       terraform apply
    
    5. View resources in each workspace:
       terraform workspace select dev
       terraform show
       
       terraform workspace select staging
       terraform show
       
       terraform workspace select prod
       terraform show
    
    6. Compare configurations:
       - Dev: ${local.env_config.dev.min_replicas} min replicas, ${local.env_config.dev.container_cpu} CPU
       - Staging: ${local.env_config.staging.min_replicas} min replicas, ${local.env_config.staging.container_cpu} CPU
       - Prod: ${local.env_config.prod.min_replicas} min replicas, ${local.env_config.prod.container_cpu} CPU
    
    7. Cleanup (run in each workspace):
       terraform workspace select dev
       terraform destroy
       
       terraform workspace select staging
       terraform destroy
       
       terraform workspace select prod
       terraform destroy
    
  EOT
}
