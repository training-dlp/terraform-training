output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  description = "Login server for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.app.name
}

output "app_url" {
  description = "URL to access the Container App"
  value       = "https://${azurerm_container_app.app.ingress[0].fqdn}"
}

output "app_fqdn" {
  description = "Fully qualified domain name of the Container App"
  value       = azurerm_container_app.app.ingress[0].fqdn
}

output "container_app_environment_id" {
  description = "ID of the Container App Environment"
  value       = azurerm_container_app_environment.env.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.app_insights.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.logs.id
}

output "acr_admin_username" {
  description = "Admin username for ACR"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Admin password for ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

# Instructions output
output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
  
  ========================================
  Deployment Complete! 
  ========================================
  
  Application URL: https://${azurerm_container_app.app.ingress[0].fqdn}
  
  To build and deploy your custom Python app:
  
  1. Build and push to ACR:
     az acr build --registry ${azurerm_container_registry.acr.name} \
       --image workshop-app:v1 ./app
  
  2. Update the container app to use your image:
     Update main.tf with image = "${azurerm_container_registry.acr.login_server}/workshop-app:v1"
     Then run: terraform apply
  
  3. View logs:
     az containerapp logs show \
       --name ${azurerm_container_app.app.name} \
       --resource-group ${azurerm_resource_group.main.name}
  
  Proceed to Day 1: State Management
  ========================================
  EOT
}
