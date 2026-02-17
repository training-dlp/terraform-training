terraform {
  required_version = ">= 1.6.0"
  
  cloud {
    organization = "your-org-name"  # Your HCP Terraform org
    
    workspaces {
      name = "day1-remote-state"
    }
  }
  
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

locals {
  prefix = "day1remote"
  tags = {
    Day         = "1"
    StateType   = "Remote"
    Workshop    = "Terraform-Advanced"
    Environment = "learning"
  }
}

# Resource Group
resource "azurerm_resource_group" "example" {
  name     = "rg-${local.prefix}-${random_string.suffix.result}"
  location = var.location
  tags     = local.tags
}

# Random suffix for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "st${local.prefix}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Enable versioning for state backup
  blob_properties {
    versioning_enabled = true
  }
  
  tags = local.tags
}

# Container in Storage Account
resource "azurerm_storage_container" "example" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "example" {
  name                = "log-${local.prefix}-${random_string.suffix.result}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.tags
}

# Output demonstrating remote state
output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "state_location" {
  value = "Remote state stored in Azure Storage backend"
}

output "backend_config" {
  value = <<-EOT
  
  Backend Configuration Active:
  - Storage Account: (configured in backend.tf)
  - Container: tfstate
  - State File: day1-remote.tfstate
  - Locking: Enabled (via blob lease)
  
  To view state:
  terraform state pull
  
  State is now shared and locked!
  EOT
}

output "state_commands" {
  value = <<-EOT
  
  Remote State Commands:
  
  1. Pull remote state:
     terraform state pull > local-copy.tfstate
  
  2. Push state (careful!):
     terraform state push local-copy.tfstate
  
  3. Verify backend config:
     terraform init -backend-config=backend.hcl
  
  4. Check lock status:
     # Try running terraform plan in two terminals
     # Second one will wait for lock release
  
  EOT
}
