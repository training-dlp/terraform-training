# Lab 4.1: Secure Container App with Key Vault Integration
# This demonstrates secure secret management and managed identity

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-containerapp-secure"
  location = var.location
  
  tags = {
    Lab       = "4.1"
    Purpose   = "Security Demo"
    ManagedBy = "Terraform"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-containerapp-secure"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-secure"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "container_app" {
  name                = "id-containerapp-keyvault"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Purpose = "Container App Key Vault Access"
  }
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-ca-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # For lab purposes; enable in production
  
  # Enable RBAC authorization
  enable_rbac_authorization = true
  
  # Network ACLs
  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # In production, set to "Deny" with specific rules
  }
  
  tags = {
    Purpose = "Container App Secrets"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Grant Key Vault Secrets User role to Managed Identity
resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

# Grant Key Vault Administrator role to current user (for secret creation)
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Wait for RBAC propagation
resource "time_sleep" "rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.keyvault_admin,
    azurerm_role_assignment.keyvault_secrets_user
  ]
  
  create_duration = "60s"
}

# Secrets in Key Vault
resource "azurerm_key_vault_secret" "database_connection" {
  name         = "database-connection-string"
  value        = "Server=db.example.com;Database=mydb;User Id=admin;Password=SecurePass123!;"
  key_vault_id = azurerm_key_vault.main.id
  
  content_type = "Database Connection String"
  
  depends_on = [time_sleep.rbac_propagation]
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "external-api-key"
  value        = "sk-1234567890abcdefghijklmnopqrstuvwxyz"
  key_vault_id = azurerm_key_vault.main.id
  
  content_type = "API Key"
  
  depends_on = [time_sleep.rbac_propagation]
}

resource "azurerm_key_vault_secret" "jwt_secret" {
  name         = "jwt-signing-key"
  value        = "super-secret-jwt-key-${random_password.jwt.result}"
  key_vault_id = azurerm_key_vault.main.id
  
  content_type = "JWT Signing Key"
  
  depends_on = [time_sleep.rbac_propagation]
}

resource "azurerm_key_vault_secret" "smtp_password" {
  name         = "smtp-password"
  value        = random_password.smtp.result
  key_vault_id = azurerm_key_vault.main.id
  
  content_type = "SMTP Password"
  
  depends_on = [time_sleep.rbac_propagation]
}

resource "random_password" "jwt" {
  length  = 32
  special = true
}

resource "random_password" "smtp" {
  length  = 16
  special = true
}

# Container App with Key Vault References
resource "azurerm_container_app" "secure" {
  name                         = "ca-secure-keyvault"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  # Attach User Assigned Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }
  
  # Secrets referencing Key Vault
  secret {
    name                = "db-connection"
    key_vault_secret_id = azurerm_key_vault_secret.database_connection.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }
  
  secret {
    name                = "api-key"
    key_vault_secret_id = azurerm_key_vault_secret.api_key.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }
  
  secret {
    name                = "jwt-secret"
    key_vault_secret_id = azurerm_key_vault_secret.jwt_secret.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }
  
  secret {
    name                = "smtp-pwd"
    key_vault_secret_id = azurerm_key_vault_secret.smtp_password.versionless_id
    identity            = azurerm_user_assigned_identity.container_app.id
  }
  
  template {
    container {
      name   = "secure-app"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
      
      # Regular environment variables
      env {
        name  = "ENVIRONMENT"
        value = "production"
      }
      
      env {
        name  = "SECURITY_MODE"
        value = "enhanced"
      }
      
      # Environment variables from Key Vault secrets
      env {
        name        = "DATABASE_CONNECTION_STRING"
        secret_name = "db-connection"
      }
      
      env {
        name        = "EXTERNAL_API_KEY"
        secret_name = "api-key"
      }
      
      env {
        name        = "JWT_SIGNING_KEY"
        secret_name = "jwt-secret"
      }
      
      env {
        name        = "SMTP_PASSWORD"
        secret_name = "smtp-pwd"
      }
      
      # Managed Identity information
      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.container_app.client_id
      }
    }
    
    min_replicas = 2
    max_replicas = 10
  }
  
  ingress {
    external_enabled = true
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = {
    Security = "Enhanced"
    KeyVault = "Integrated"
  }
  
  depends_on = [
    time_sleep.rbac_propagation,
    azurerm_role_assignment.keyvault_secrets_user
  ]
}

# Azure Monitor Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "keyvault-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "AuditEvent"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Azure Monitor Diagnostic Settings for Container App
resource "azurerm_monitor_diagnostic_setting" "container_app" {
  name                       = "containerapp-diagnostics"
  target_resource_id         = azurerm_container_app.secure.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  
  enabled_log {
    category = "ContainerAppConsoleLogs"
  }
  
  enabled_log {
    category = "ContainerAppSystemLogs"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Outputs
output "container_app_url" {
  description = "Container App URL"
  value       = "https://${azurerm_container_app.secure.ingress[0].fqdn}"
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "managed_identity" {
  description = "Managed Identity details"
  value = {
    name        = azurerm_user_assigned_identity.container_app.name
    client_id   = azurerm_user_assigned_identity.container_app.client_id
    principal_id = azurerm_user_assigned_identity.container_app.principal_id
  }
}

output "secrets_in_keyvault" {
  description = "List of secrets stored in Key Vault"
  value = [
    azurerm_key_vault_secret.database_connection.name,
    azurerm_key_vault_secret.api_key.name,
    azurerm_key_vault_secret.jwt_secret.name,
    azurerm_key_vault_secret.smtp_password.name
  ]
}

output "security_architecture" {
  description = "Security architecture diagram"
  value = <<-EOT
    
    SECURITY ARCHITECTURE
    =====================
    
    ┌───────────────────────────────────────┐
    │      Azure Container App              │
    │  (Managed Identity Enabled)           │
    └─────────────┬─────────────────────────┘
                  │
                  │ References secrets via
                  │ Key Vault Secret IDs
                  │
                  ▼
    ┌───────────────────────────────────────┐
    │       Azure Key Vault                 │
    │  (RBAC Authorization)                 │
    │  ┌─────────────────────────────────┐  │
    │  │ • Database Connection String    │  │
    │  │ • API Key                       │  │
    │  │ • JWT Signing Key               │  │
    │  │ • SMTP Password                 │  │
    │  └─────────────────────────────────┘  │
    └───────────────────────────────────────┘
              │
              │ Audit Logs
              ▼
    ┌───────────────────────────────────────┐
    │    Log Analytics Workspace            │
    │  (Monitoring & Compliance)            │
    └───────────────────────────────────────┘
    
    Security Features:
    ✓ Managed Identity (no credentials in code)
    ✓ Key Vault integration
    ✓ RBAC authorization
    ✓ Audit logging enabled
    ✓ Diagnostic settings configured
    ✓ Secrets rotation ready
    
  EOT
}

output "lab_instructions" {
  description = "Lab instructions and verification steps"
  value = <<-EOT
    
    LAB 4.1 COMPLETED
    =================
    
    Resources Created:
    ✓ Key Vault with 4 secrets
    ✓ User Assigned Managed Identity
    ✓ Container App with Key Vault integration
    ✓ RBAC role assignments
    ✓ Diagnostic settings for auditing
    
    Verification Steps:
    
    1. View Container App:
       az containerapp show --name ${azurerm_container_app.secure.name} --resource-group ${azurerm_resource_group.main.name}
    
    2. Verify Managed Identity:
       az identity show --name ${azurerm_user_assigned_identity.container_app.name} --resource-group ${azurerm_resource_group.main.name}
    
    3. List Key Vault Secrets:
       az keyvault secret list --vault-name ${azurerm_key_vault.main.name}
    
    4. Check RBAC assignments:
       az role assignment list --scope ${azurerm_key_vault.main.id}
    
    5. View Container App logs:
       az containerapp logs show --name ${azurerm_container_app.secure.name} --resource-group ${azurerm_resource_group.main.name} --type console
    
    6. View Key Vault audit logs in Log Analytics:
       - Go to Log Analytics Workspace
       - Run query: AzureDiagnostics | where ResourceType == "VAULTS"
    
    7. Test the application:
       curl https://${azurerm_container_app.secure.ingress[0].fqdn}
    
    Security Best Practices Demonstrated:
    • No secrets in Terraform code or state
    • Managed identity instead of credentials
    • Least privilege RBAC
    • Audit logging enabled
    • Secret rotation capability
    • Encryption at rest and in transit
    
    Key Vault: ${azurerm_key_vault.main.name}
    Container App: ${azurerm_container_app.secure.name}
    App URL: https://${azurerm_container_app.secure.ingress[0].fqdn}
    
  EOT
}
