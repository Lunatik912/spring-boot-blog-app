output "resource_group_name" {
  description = "Name of the application resource group"
  value       = azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Name of the application VNet"
  value       = azurerm_virtual_network.main.name
}

output "container_apps_subnet_id" {
  description = "ID of the Container Apps subnet"
  value       = azurerm_subnet.container_apps.id
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}
