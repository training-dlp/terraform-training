# Lab 3.1: Container App Module - Outputs
# File: modules/container-app/outputs.tf

output "id" {
  description = "The ID of the Container App"
  value       = azurerm_container_app.main.id
}

output "name" {
  description = "The name of the Container App"
  value       = azurerm_container_app.main.name
}

output "fqdn" {
  description = "The FQDN of the Container App's ingress (if enabled)"
  value       = var.ingress_enabled ? azurerm_container_app.main.ingress[0].fqdn : null
}

output "url" {
  description = "The full URL of the Container App (if external ingress is enabled)"
  value       = var.ingress_enabled && var.external_enabled ? "https://${azurerm_container_app.main.ingress[0].fqdn}" : null
}

output "latest_revision_name" {
  description = "The name of the latest revision"
  value       = azurerm_container_app.main.latest_revision_name
}

output "latest_revision_fqdn" {
  description = "The FQDN of the latest revision"
  value       = azurerm_container_app.main.latest_revision_fqdn
}

output "outbound_ip_addresses" {
  description = "List of outbound IP addresses for the Container App"
  value       = azurerm_container_app.main.outbound_ip_addresses
}

output "custom_domain_verification_id" {
  description = "The ID used for custom domain verification"
  value       = azurerm_container_app.main.custom_domain_verification_id
}

output "configuration" {
  description = "Configuration summary of the Container App"
  value = {
    name          = var.name
    image         = var.container_image
    cpu           = var.cpu
    memory        = var.memory
    min_replicas  = var.min_replicas
    max_replicas  = var.max_replicas
    revision_mode = var.revision_mode
    ingress = {
      enabled  = var.ingress_enabled
      external = var.external_enabled
      port     = var.target_port
    }
    dapr = {
      enabled = var.dapr_enabled
      app_id  = var.dapr_app_id
      port    = var.dapr_app_port
    }
  }
}
