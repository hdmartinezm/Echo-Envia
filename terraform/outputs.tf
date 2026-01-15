output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = module.networking.vnet_name
}

output "app_gateway_public_ip" {
  description = "IP pública del Application Gateway"
  value       = module.gateway.public_ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN del Application Gateway"
  value       = module.gateway.public_ip_fqdn
}

output "app_service_names" {
  description = "Nombres de los App Services"
  value       = module.compute.app_service_names
}

output "app_service_urls" {
  description = "URLs de los App Services"
  value       = module.compute.app_service_default_hostnames
}

output "mysql_server_fqdn" {
  description = "FQDN del MySQL Server"
  value       = module.database.mysql_fqdn
}

output "mysql_database_name" {
  description = "Nombre de la base de datos MySQL"
  value       = var.mysql_database_name
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = module.security.key_vault_uri
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = module.storage.storage_account_name
}

output "storage_account_primary_endpoint" {
  description = "Endpoint primario del Storage Account"
  value       = module.storage.primary_blob_endpoint
}

# Información sensible (marcada como sensitive)
output "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  value       = var.mysql_admin_username
  sensitive   = true
}

output "deployment_summary" {
  description = "Resumen del despliegue"
  value = {
    environment           = var.environment
    location              = var.location
    resource_group        = azurerm_resource_group.main.name
    app_gateway_ip        = module.gateway.public_ip_address
    app_services_count    = var.app_service_instances
    mysql_ha_enabled      = var.mysql_high_availability_mode != "Disabled"
    private_endpoints     = var.enable_private_endpoints
  }
}
