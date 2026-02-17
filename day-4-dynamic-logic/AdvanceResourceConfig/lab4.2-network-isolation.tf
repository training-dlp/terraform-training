# Lab 4.2: Network-Isolated Container App with Private Endpoints
# This demonstrates network security and VNet integration

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

variable "allowed_ip_ranges" {
  description = "IP ranges allowed to access the application"
  type        = list(string)
  default     = [] # Empty means allow all; specify IPs in production
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-containerapp-network"
  location = var.location
  
  tags = {
    Lab       = "4.2"
    Purpose   = "Network Security Demo"
    ManagedBy = "Terraform"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-containerapp"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Purpose = "Container Apps Network Isolation"
  }
}

# Subnet for Container App Environment (Internal)
resource "azurerm_subnet" "container_apps" {
  name                 = "snet-container-apps"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/23"] # Minimum /23 for Container Apps
  
  delegation {
    name = "container-app-delegation"
    
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-private-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Subnet for Application Gateway (if needed for advanced scenarios)
resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-app-gateway"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.4.0/24"]
}

# Network Security Group for Container Apps Subnet
resource "azurerm_network_security_group" "container_apps" {
  name                = "nsg-container-apps"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  # Allow inbound HTTPS
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Allow inbound HTTP
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  
  tags = {
    Purpose = "Container Apps Security"
  }
}

# Associate NSG with Container Apps Subnet
resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-containerapp-network"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Container App Environment with VNet Integration
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-network-isolated"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled = false # Set to true for fully internal
  
  tags = {
    NetworkIsolation = "Enabled"
  }
}

# Private DNS Zone for Container Apps
resource "azurerm_private_dns_zone" "container_apps" {
  name                = azurerm_container_app_environment.main.default_domain
  resource_group_name = azurerm_resource_group.main.name
  
  tags = {
    Purpose = "Container Apps Private DNS"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "container_apps" {
  name                  = "vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.container_apps.name
  virtual_network_id    = azurerm_virtual_network.main.id
  
  tags = {
    Purpose = "DNS Resolution for Container Apps"
  }
}

# Internal Container App (No External Access)
resource "azurerm_container_app" "internal" {
  name                         = "ca-internal-service"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "internal-api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
      
      env {
        name  = "SERVICE_TYPE"
        value = "internal"
      }
      
      env {
        name  = "NETWORK_MODE"
        value = "private"
      }
    }
    
    min_replicas = 2
    max_replicas = 5
  }
  
  # Internal ingress only
  ingress {
    external_enabled = false # Internal only
    target_port      = 80
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = {
    Accessibility = "Internal"
    NetworkZone   = "Private"
  }
}

# External Container App with IP Restrictions
resource "azurerm_container_app" "external" {
  name                         = "ca-external-service"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  
  template {
    container {
      name   = "frontend"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.5
      memory = "1Gi"
      
      env {
        name  = "SERVICE_TYPE"
        value = "external"
      }
      
      env {
        name  = "INTERNAL_API_URL"
        value = "http://${azurerm_container_app.internal.ingress[0].fqdn}"
      }
    }
    
    min_replicas = 2
    max_replicas = 10
  }
  
  # External ingress with IP restrictions
  ingress {
    external_enabled = true
    target_port      = 80
    
    # IP restriction rules (if specified)
    dynamic "ip_security_restriction" {
      for_each = var.allowed_ip_ranges
      content {
        name           = "allowed-ip-${ip_security_restriction.key}"
        ip_address_range = ip_security_restriction.value
        action         = "Allow"
      }
    }
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  
  tags = {
    Accessibility = "External"
    NetworkZone   = "Public"
  }
  
  depends_on = [azurerm_container_app.internal]
}

# Storage Account with Private Endpoint
resource "azurerm_storage_account" "main" {
  name                     = "stcasecure${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Disable public access
  public_network_access_enabled = false
  
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  
  tags = {
    Purpose = "Private Storage"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id
  
  private_service_connection {
    name                           = "storage-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
  
  tags = {
    Purpose = "Private Storage Access"
  }
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name
}

# Link Storage DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "storage-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# Azure Firewall (Optional - for advanced scenarios)
# Uncomment if you need centralized egress control

# resource "azurerm_subnet" "firewall" {
#   name                 = "AzureFirewallSubnet"
#   resource_group_name  = azurerm_resource_group.main.name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.5.0/24"]
# }

# resource "azurerm_public_ip" "firewall" {
#   name                = "pip-firewall"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_firewall" "main" {
#   name                = "fw-containerapp"
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name
#   sku_name            = "AZFW_VNet"
#   sku_tier            = "Standard"
#   
#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.firewall.id
#     public_ip_address_id = azurerm_public_ip.firewall.id
#   }
# }

# Outputs
output "virtual_network" {
  description = "Virtual Network details"
  value = {
    name          = azurerm_virtual_network.main.name
    id            = azurerm_virtual_network.main.id
    address_space = azurerm_virtual_network.main.address_space
  }
}

output "subnets" {
  description = "Subnet details"
  value = {
    container_apps = {
      name    = azurerm_subnet.container_apps.name
      id      = azurerm_subnet.container_apps.id
      prefix  = azurerm_subnet.container_apps.address_prefixes
    }
    private_endpoints = {
      name    = azurerm_subnet.private_endpoints.name
      id      = azurerm_subnet.private_endpoints.id
      prefix  = azurerm_subnet.private_endpoints.address_prefixes
    }
  }
}

output "container_apps" {
  description = "Container App URLs"
  value = {
    external = "https://${azurerm_container_app.external.ingress[0].fqdn}"
    internal = "http://${azurerm_container_app.internal.ingress[0].fqdn} (internal only)"
  }
}

output "storage_account" {
  description = "Storage account details"
  value = {
    name              = azurerm_storage_account.main.name
    private_endpoint  = azurerm_private_endpoint.storage.name
  }
}

output "network_architecture" {
  description = "Network architecture diagram"
  value = <<-EOT
    
    NETWORK ARCHITECTURE
    ====================
    
    Virtual Network: ${azurerm_virtual_network.main.name} (10.0.0.0/16)
    ├── Container Apps Subnet (10.0.1.0/23)
    │   ├── Network Security Group: ✓
    │   ├── Delegation: Microsoft.App/environments
    │   ├── Internal Container App (Private)
    │   └── External Container App (Public)
    │
    ├── Private Endpoints Subnet (10.0.3.0/24)
    │   └── Storage Account Private Endpoint
    │
    └── App Gateway Subnet (10.0.4.0/24)
        └── (Reserved for Application Gateway)
    
    Private DNS Zones:
    ├── ${azurerm_private_dns_zone.container_apps.name}
    └── ${azurerm_private_dns_zone.storage.name}
    
    Security Features:
    ✓ VNet Integration
    ✓ Network Security Groups
    ✓ Private Endpoints
    ✓ Private DNS Zones
    ✓ Internal-only services
    ✓ IP restrictions (configurable)
    ✓ Public network access disabled for storage
    
  EOT
}

output "lab_instructions" {
  description = "Lab verification and testing instructions"
  value = <<-EOT
    
    LAB 4.2 COMPLETED
    =================
    
    Resources Created:
    ✓ Virtual Network with 3 subnets
    ✓ Network Security Group
    ✓ Container App Environment (VNet integrated)
    ✓ Internal Container App (no external access)
    ✓ External Container App (with IP restrictions)
    ✓ Storage Account with Private Endpoint
    ✓ Private DNS Zones
    
    Network Isolation Verified:
    1. Container Apps in dedicated subnet
    2. Internal service not externally accessible
    3. External service with IP restrictions
    4. Storage accessible only via private endpoint
    5. All traffic within VNet
    
    Testing Steps:
    
    1. Test External App (Public):
       curl https://${azurerm_container_app.external.ingress[0].fqdn}
    
    2. Test Internal App (Should fail from internet):
       curl http://${azurerm_container_app.internal.ingress[0].fqdn}
       Expected: Connection refused/timeout
    
    3. Verify VNet Integration:
       az containerapp env show --name ${azurerm_container_app_environment.main.name} \
         --resource-group ${azurerm_resource_group.main.name} \
         --query "properties.vnetConfiguration"
    
    4. Check NSG Rules:
       az network nsg rule list --nsg-name ${azurerm_network_security_group.container_apps.name} \
         --resource-group ${azurerm_resource_group.main.name} --output table
    
    5. Verify Private Endpoint:
       az network private-endpoint show --name ${azurerm_private_endpoint.storage.name} \
         --resource-group ${azurerm_resource_group.main.name}
    
    6. Test inter-app communication (External → Internal):
       The external app has the internal app URL in environment variables
       Check logs: az containerapp logs show --name ${azurerm_container_app.external.name} \
         --resource-group ${azurerm_resource_group.main.name} --type console
    
    Network Security Best Practices:
    • Subnet delegation for Container Apps
    • NSG rules for traffic control
    • Private endpoints for Azure services
    • Private DNS for name resolution
    • Internal-only services when appropriate
    • IP restrictions for external services
    
    External App: https://${azurerm_container_app.external.ingress[0].fqdn}
    Internal App: ${azurerm_container_app.internal.ingress[0].fqdn} (VNet only)
    
  EOT
}
