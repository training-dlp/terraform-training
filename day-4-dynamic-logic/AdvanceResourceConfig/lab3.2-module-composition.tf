# Lab 3.2: Module Composition - Full Application Stack
# This demonstrates composing multiple modules to build complex infrastructure

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

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# 1. Networking Module
module "networking" {
  source = "./modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  vnet_address_space        = ["10.0.0.0/16"]
  infrastructure_subnet     = "10.0.1.0/24"
  container_apps_subnet     = "10.0.2.0/24"
  private_endpoints_subnet  = "10.0.3.0/24"
}

# 2. Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  retention_days = 30
  enable_application_insights = true
}

# 3. Container App Environment Module
module "container_environment" {
  source = "./modules/container-environment"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id
  infrastructure_subnet_id   = module.networking.container_apps_subnet_id
  
  # Pass Application Insights for Dapr
  dapr_instrumentation_key = module.monitoring.application_insights_instrumentation_key
  
  depends_on = [
    module.networking,
    module.monitoring
  ]
}

# 4. Frontend Container App using Container App Module
module "frontend_app" {
  source = "./modules/container-app"
  
  name                         = "frontend-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_environment.id
  
  container_image = "nginx:alpine"
  cpu             = 0.5
  memory          = "1Gi"
  
  min_replicas = 2
  max_replicas = 10
  
  environment_variables = {
    "BACKEND_URL" = {
      name  = "BACKEND_URL"
      value = module.backend_app.fqdn
    }
    "API_GATEWAY_URL" = {
      name  = "API_GATEWAY_URL"
      value = module.api_gateway.fqdn
    }
    "ENVIRONMENT" = {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }
  
  tags = {
    Component = "Frontend"
  }
  
  depends_on = [module.container_environment]
}

# 5. Backend API using Container App Module
module "backend_app" {
  source = "./modules/container-app"
  
  name                         = "backend-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_environment.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 1.0
  memory          = "2Gi"
  
  min_replicas = 2
  max_replicas = 15
  
  environment_variables = {
    "DATABASE_HOST" = {
      name  = "DATABASE_HOST"
      value = module.database.fqdn
    }
    "CACHE_ENDPOINT" = {
      name  = "CACHE_ENDPOINT"
      value = module.redis.hostname
    }
    "STORAGE_ACCOUNT" = {
      name  = "STORAGE_ACCOUNT"
      value = module.storage.name
    }
    "ENVIRONMENT" = {
      name  = "ENVIRONMENT"
      value = var.environment
    }
  }
  
  secrets = {
    "db-password" = {
      name  = "database-password"
      value = module.database.admin_password
    }
    "storage-key" = {
      name  = "storage-key"
      value = module.storage.primary_access_key
    }
  }
  
  health_check_path = "/api/health"
  
  tags = {
    Component = "Backend"
  }
  
  depends_on = [
    module.container_environment,
    module.database,
    module.redis,
    module.storage
  ]
}

# 6. API Gateway using Container App Module
module "api_gateway" {
  source = "./modules/container-app"
  
  name                         = "api-gateway-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = module.container_environment.id
  
  container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
  cpu             = 0.5
  memory          = "1Gi"
  
  min_replicas = 3
  max_replicas = 20
  
  environment_variables = {
    "BACKEND_SERVICE" = {
      name  = "BACKEND_SERVICE"
      value = module.backend_app.fqdn
    }
    "RATE_LIMIT" = {
      name  = "RATE_LIMIT"
      value = "1000"
    }
  }
  
  http_concurrent_requests = 20
  
  tags = {
    Component = "API Gateway"
  }
  
  depends_on = [
    module.container_environment,
    module.backend_app
  ]
}

# 7. Database Module (PostgreSQL)
module "database" {
  source = "./modules/database"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  database_name    = "appdb"
  admin_username   = "dbadmin"
  
  # Network integration
  subnet_id = module.networking.private_endpoints_subnet_id
  
  tags = {
    Component = "Database"
  }
  
  depends_on = [module.networking]
}

# 8. Redis Cache Module
module "redis" {
  source = "./modules/redis"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  capacity = 1
  family   = "C"
  sku_name = "Basic"
  
  # Network integration
  subnet_id = module.networking.private_endpoints_subnet_id
  
  tags = {
    Component = "Cache"
  }
  
  depends_on = [module.networking]
}

# 9. Storage Module
module "storage" {
  source = "./modules/storage"
  
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  
  # Network integration
  subnet_id = module.networking.private_endpoints_subnet_id
  
  containers = ["uploads", "exports", "backups"]
  
  tags = {
    Component = "Storage"
  }
  
  depends_on = [module.networking]
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-app-stack-${var.environment}"
  location = var.location
  
  tags = {
    Lab         = "3.2"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "application_urls" {
  description = "URLs for accessing the application"
  value = {
    frontend    = module.frontend_app.url
    backend     = module.backend_app.url
    api_gateway = module.api_gateway.url
  }
}

output "infrastructure_endpoints" {
  description = "Infrastructure service endpoints"
  value = {
    database = module.database.fqdn
    redis    = module.redis.hostname
    storage  = module.storage.primary_blob_endpoint
  }
  sensitive = true
}

output "monitoring" {
  description = "Monitoring endpoints"
  value = {
    log_analytics_workspace = module.monitoring.log_analytics_workspace_id
    application_insights    = module.monitoring.application_insights_id
  }
}

output "network_info" {
  description = "Network configuration"
  value = {
    vnet_id                   = module.networking.vnet_id
    vnet_name                 = module.networking.vnet_name
    container_apps_subnet_id  = module.networking.container_apps_subnet_id
    private_endpoints_subnet  = module.networking.private_endpoints_subnet_id
  }
}

output "architecture_diagram" {
  description = "Application architecture"
  value = <<-EOT
    
    APPLICATION ARCHITECTURE
    ========================
    
    ┌─────────────────────────────────────────────────────┐
    │                    Internet                         │
    └──────────────────┬──────────────────────────────────┘
                       │
                       ▼
    ┌──────────────────────────────────────────────────────┐
    │              API Gateway (Public)                    │
    │  ${module.api_gateway.fqdn}  │
    └──────────────────┬───────────────────────────────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
           ▼                       ▼
    ┌─────────────┐         ┌─────────────┐
    │  Frontend   │◄────────┤   Backend   │
    │  (Public)   │         │  (Public)   │
    └─────────────┘         └──────┬──────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌──────────┐   ┌──────────┐   ┌──────────┐
            │ Database │   │  Redis   │   │ Storage  │
            │ (Private)│   │ (Private)│   │ (Private)│
            └──────────┘   └──────────┘   └──────────┘
    
    Virtual Network: ${module.networking.vnet_name}
    Monitoring: Log Analytics + Application Insights
    
  EOT
}

output "lab_completion" {
  description = "Lab completion summary"
  value = <<-EOT
    
    LAB 3.2 COMPLETED
    =================
    
    Modules Composed:
    ├── Networking Module (VNet, Subnets)
    ├── Monitoring Module (Log Analytics, App Insights)
    ├── Container Environment Module
    ├── Container App Module (3 instances)
    │   ├── Frontend
    │   ├── Backend
    │   └── API Gateway
    ├── Database Module (PostgreSQL)
    ├── Redis Module (Cache)
    └── Storage Module (Blob Storage)
    
    Total Resources: 20+ Azure resources
    Module Dependencies: Properly managed
    Data Flow: Outputs → Inputs between modules
    
    Application Stack URLs:
    - Frontend: ${module.frontend_app.url}
    - Backend: ${module.backend_app.url}
    - API Gateway: ${module.api_gateway.url}
    
    Key Learnings:
    1. Module composition patterns
    2. Inter-module dependencies
    3. Passing data between modules
    4. Shared infrastructure pattern
    5. Network isolation and security
    6. Comprehensive output structure
    
    Test the Application:
    1. Access frontend URL
    2. Test API Gateway
    3. Verify backend connectivity
    4. Check monitoring dashboards
    
  EOT
}
