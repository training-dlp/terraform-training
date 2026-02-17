# Lab 1.1: Setting Up Remote State with Azure Storage
# This lab demonstrates configuring Azure Blob Storage as remote backend

# Step 1: Create Azure Storage Account for state management
# Run this first to create the storage account

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

# Variables for storage account
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Resource Group for Terraform State
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-terraform-state-${var.environment}"
  location = var.location

  tags = {
    Purpose     = "Terraform State Management"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Storage Account for Terraform State
resource "azurerm_storage_account" "tfstate" {
  name                     = "tfstate${var.environment}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-redundant for disaster recovery
  
  # Enable versioning for state file history
  blob_properties {
    versioning_enabled = true
    
    # Retain deleted blobs for 30 days
    delete_retention_policy {
      days = 30
    }
  }

  # Enable encryption at rest
  min_tls_version = "TLS1_2"
  
  tags = {
    Purpose     = "Terraform State Storage"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Random suffix for unique storage account name
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Storage Container for state files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Output values for backend configuration
output "storage_account_name" {
  description = "Storage account name for backend configuration"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Container name for backend configuration"
  value       = azurerm_storage_container.tfstate.name
}

output "resource_group_name" {
  description = "Resource group name for backend configuration"
  value       = azurerm_resource_group.tfstate.name
}

output "backend_configuration" {
  description = "Backend configuration snippet"
  value = <<-EOT
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "terraform.tfstate"
      }
    }
  EOT
}

# Instructions
output "next_steps" {
  description = "Next steps to configure backend"
  value = <<-EOT
    
    NEXT STEPS:
    -----------
    1. Copy the backend configuration above
    2. Create a new file named 'backend.tf'
    3. Paste the configuration into backend.tf
    4. Run: terraform init -reconfigure
    5. Confirm state migration when prompted
    6. Verify state is stored in Azure: az storage blob list --account-name ${azurerm_storage_account.tfstate.name} --container-name ${azurerm_storage_container.tfstate.name}
    
  EOT
}
