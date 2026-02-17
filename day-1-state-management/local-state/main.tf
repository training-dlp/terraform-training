terraform {
  required_version = ">= 1.6.0"
  cloud {
    organization = "ExperionTraining"  # Your HCP Terraform org
    
    workspaces {
      name = "day1-local-state"
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
  prefix = "day1local"
  tags = {
    Day         = "1"
    StateType   = "Local"
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
  
  tags = local.tags
}

# Container in Storage Account
resource "azurerm_storage_container" "example" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

# Output demonstrating state queries
output "resource_group_name" {
  value = azurerm_resource_group.example.name
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "state_location" {
  value = "Local state file: terraform.tfstate in current directory"
}

output "state_commands" {
  value = <<-EOT
  
  Useful state commands to try:
  
  1. List all resources:
     terraform state list
  
  2. Show resource details:
     terraform state show azurerm_resource_group.example
  
  3. Pull state to stdout:
     terraform state pull
  
  4. View state file directly:
     cat terraform.tfstate | jq '.resources'
  
  EOT
}
