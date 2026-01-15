output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "app_gateway_subnet_id" {
  description = "ID de la subnet del Application Gateway"
  value       = azurerm_subnet.app_gateway.id
}

output "app_service_subnet_id" {
  description = "ID de la subnet del App Service"
  value       = azurerm_subnet.app_service.id
}

output "private_endpoint_subnet_id" {
  description = "ID de la subnet de Private Endpoints"
  value       = azurerm_subnet.private_endpoint.id
}

output "mysql_private_dns_zone_id" {
  description = "ID de la Private DNS Zone de MySQL"
  value       = azurerm_private_dns_zone.mysql.id
}

output "storage_private_dns_zone_ids" {
  description = "IDs de las Private DNS Zones de Storage"
  value = {
    blob = azurerm_private_dns_zone.storage_blob.id
    file = azurerm_private_dns_zone.storage_file.id
  }
}

output "keyvault_private_dns_zone_id" {
  description = "ID de la Private DNS Zone de Key Vault"
  value       = azurerm_private_dns_zone.keyvault.id
}
