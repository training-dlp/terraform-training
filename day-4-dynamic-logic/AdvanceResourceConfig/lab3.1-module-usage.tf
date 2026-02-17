# Lab 3.1: Using the Container App Module
# This demonstrates how to use the reusable module

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

# Shared Infrastructure
resource "azurerm_resource_group" "main" {
  name     = "rg-containerapp-module"
  location = var.location
  
  tags = {
    Lab     = "3.1"
    Purpose = "Module demonstration"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-containerapp-module"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-module"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# Example 1: Simple Container App using the module
module "simple_app" {
  source = "./modules/container-app"
  
  name                         = "simple-app"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 0.25
  memory          = "0.5Gi"
  
  min_replicas = 1
  max_replicas = 3
  
  tags = {
    Application = "Simple App"
    Tier        = "Basic"
  }
}

# Example 2: Container App with Environment Variables
module "configured_app" {
  source = "./modules/container-app"
  
  name                         = "configured-app"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "nginx:alpine"
  cpu             = 0.5
  memory          = "1Gi"
  
  min_replicas = 2
  max_replicas = 8
  
  environment_variables = {
    "ENVIRONMENT" = {
      name  = "ENVIRONMENT"
      value = "production"
    }
    "LOG_LEVEL" = {
      name  = "LOG_LEVEL"
      value = "INFO"
    }
    "MAX_CONNECTIONS" = {
      name  = "MAX_CONNECTIONS"
      value = "100"
    }
  }
  
  health_check_path = "/"
  
  tags = {
    Application = "Web Server"
    Tier        = "Standard"
  }
}

# Example 3: Container App with Secrets
module "secure_app" {
  source = "./modules/container-app"
  
  name                         = "secure-app"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 0.5
  memory          = "1Gi"
  
  min_replicas = 2
  max_replicas = 10
  
  # Regular environment variables
  environment_variables = {
    "APP_NAME" = {
      name  = "APP_NAME"
      value = "Secure Application"
    }
    "DB_HOST" = {
      name  = "DB_HOST"
      value = "db.example.com"
    }
    # Reference to secret
    "DB_PASSWORD" = {
      name        = "DB_PASSWORD"
      secret_name = "database-password"
    }
    "API_KEY" = {
      name        = "API_KEY"
      secret_name = "api-key"
    }
  }
  
  # Secrets
  secrets = {
    "db-password" = {
      name  = "database-password"
      value = "SecurePassword123!" # In production, use Key Vault or variable
    }
    "api-key" = {
      name  = "api-key"
      value = "sk-1234567890abcdef"
    }
  }
  
  enable_health_probes = true
  health_check_path    = "/health"
  
  tags = {
    Application = "Secure API"
    Tier        = "Premium"
    Security    = "High"
  }
}

# Example 4: High-Performance Container App
module "high_perf_app" {
  source = "./modules/container-app"
  
  name                         = "high-perf-app"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 2.0
  memory          = "4Gi"
  
  min_replicas = 3
  max_replicas = 30
  
  # Aggressive scaling
  enable_http_scale_rule   = true
  http_concurrent_requests = 5  # Scale quickly
  
  environment_variables = {
    "PERFORMANCE_MODE" = {
      name  = "PERFORMANCE_MODE"
      value = "high"
    }
    "CACHE_ENABLED" = {
      name  = "CACHE_ENABLED"
      value = "true"
    }
  }
  
  tags = {
    Application = "High Performance API"
    Tier        = "Enterprise"
    Performance = "Optimized"
  }
}

# Example 5: Internal Service (No External Access)
module "internal_service" {
  source = "./modules/container-app"
  
  name                         = "internal-worker"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 1.0
  memory          = "2Gi"
  
  min_replicas = 1
  max_replicas = 5
  
  # Disable external access
  ingress_enabled  = false
  
  environment_variables = {
    "SERVICE_TYPE" = {
      name  = "SERVICE_TYPE"
      value = "internal"
    }
    "QUEUE_URL" = {
      name  = "QUEUE_URL"
      value = "https://internal-queue.local"
    }
  }
  
  # Disable HTTP scaling since this is not an HTTP service
  enable_http_scale_rule = false
  
  tags = {
    Application = "Background Worker"
    Tier        = "Internal"
    Type        = "Worker"
  }
}

# Outputs
output "simple_app_url" {
  description = "Simple app URL"
  value       = module.simple_app.url
}

output "configured_app_url" {
  description = "Configured app URL"
  value       = module.configured_app.url
}

output "secure_app_url" {
  description = "Secure app URL"
  value       = module.secure_app.url
}

output "high_perf_app_url" {
  description = "High performance app URL"
  value       = module.high_perf_app.url
}

output "internal_service_name" {
  description = "Internal service name (no external URL)"
  value       = module.internal_service.name
}

output "all_apps_configuration" {
  description = "Configuration summary of all deployed apps"
  value = {
    simple_app       = module.simple_app.configuration
    configured_app   = module.configured_app.configuration
    secure_app       = module.secure_app.configuration
    high_perf_app    = module.high_perf_app.configuration
    internal_service = module.internal_service.configuration
  }
}

output "lab_completion" {
  description = "Lab completion summary"
  value = <<-EOT
    
    LAB 3.1 COMPLETED
    =================
    
    Module Created: ✓
    - Location: modules/container-app/
    - Files: main.tf, variables.tf, outputs.tf, README.md
    
    Module Features:
    - Input validation for all parameters
    - Comprehensive configuration options
    - Secrets management
    - Health probes
    - Auto-scaling rules
    - Dapr support
    - Complete documentation
    
    Deployed Applications Using Module:
    1. Simple App: ${module.simple_app.url}
    2. Configured App: ${module.configured_app.url}
    3. Secure App (with secrets): ${module.secure_app.url}
    4. High Performance App: ${module.high_perf_app.url}
    5. Internal Service: ${module.internal_service.name} (internal only)
    
    Key Learnings:
    - Module structure and organization
    - Input validation best practices
    - Dynamic blocks in modules
    - Reusable and maintainable code
    - Comprehensive outputs
    - Module documentation
    
    Next Steps:
    1. Review module documentation: cat modules/container-app/README.md
    2. Test different configurations
    3. Create additional examples
    4. Version the module
    5. Publish to module registry (optional)
    
  EOT
}
