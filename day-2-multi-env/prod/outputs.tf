output "app_url" {
  value = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "environment" {
  value = var.environment
}
