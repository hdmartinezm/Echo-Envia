# Echo-Envia - Outputs Simplificados

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = data.azurerm_resource_group.main.name
}

output "vnet_name" {
  description = "Nombre de la Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "vnet_id" {
  description = "ID de la Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "mysql_server_fqdn" {
  description = "FQDN del servidor MySQL"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_database_name" {
  description = "Nombre de la base de datos MySQL"
  value       = azurerm_mysql_flexible_database.main.name
}

output "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  value       = var.mysql_admin_username
  sensitive   = true
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "storage_account_name" {
  description = "Nombre de la Storage Account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_endpoint" {
  description = "Endpoint primario de la Storage Account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "app_service_names" {
  description = "Nombres de las App Services"
  value       = [for app in azurerm_linux_web_app.main : app.name]
}

output "app_service_urls" {
  description = "URLs de las App Services"
  value       = [for app in azurerm_linux_web_app.main : "https://${app.default_hostname}"]
}

output "app_gateway_public_ip" {
  description = "IP pública del Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "app_gateway_fqdn" {
  description = "FQDN del Application Gateway"
  value       = azurerm_public_ip.app_gateway.fqdn
}

output "deployment_summary" {
  description = "Resumen del despliegue"
  value = {
    resource_group         = data.azurerm_resource_group.main.name
    location              = data.azurerm_resource_group.main.location
    environment           = var.environment
    app_services_count    = length(azurerm_linux_web_app.main)
    mysql_ha_enabled      = var.mysql_high_availability_mode != "Disabled"
    mysql_replica_enabled = var.enable_mysql_replica
    app_gateway_ip        = azurerm_public_ip.app_gateway.ip_address
    app_gateway_fqdn      = azurerm_public_ip.app_gateway.fqdn
    front_door_endpoint   = azurerm_cdn_frontdoor_endpoint.main.host_name
    private_endpoints = {
      mysql_enabled    = var.enable_mysql_private_endpoint
      storage_enabled  = var.enable_storage_private_endpoint
      keyvault_enabled = var.enable_keyvault_private_endpoint
    }
  }
}

# Azure Front Door Outputs
output "front_door_profile_name" {
  description = "Nombre del perfil de Azure Front Door"
  value       = azurerm_cdn_frontdoor_profile.main.name
}

output "front_door_endpoint_hostname" {
  description = "Hostname del endpoint de Front Door"
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "front_door_endpoint_url" {
  description = "URL completa del endpoint de Front Door"
  value       = "https://${azurerm_cdn_frontdoor_endpoint.main.host_name}"
}

# Private Endpoints Outputs
output "mysql_private_endpoint_ip" {
  description = "IP privada del endpoint de MySQL"
  value       = var.enable_mysql_private_endpoint ? azurerm_private_endpoint.mysql[0].private_service_connection[0].private_ip_address : null
}

output "storage_private_endpoint_ip" {
  description = "IP privada del endpoint de Storage"
  value       = var.enable_storage_private_endpoint ? azurerm_private_endpoint.storage[0].private_service_connection[0].private_ip_address : null
}

output "keyvault_private_endpoint_ip" {
  description = "IP privada del endpoint de Key Vault"
  value       = var.enable_keyvault_private_endpoint ? azurerm_private_endpoint.keyvault[0].private_service_connection[0].private_ip_address : null
}

# MySQL Replica Output
output "mysql_replica_fqdn" {
  description = "FQDN del servidor MySQL replica"
  value       = var.enable_mysql_replica ? azurerm_mysql_flexible_server.replica[0].fqdn : null
}

# Azure Container Registry Outputs
output "container_registry_name" {
  description = "Nombre del Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server del Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Usuario administrador del ACR"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

# Redis Outputs
output "redis_hostname" {
  description = "Hostname del Azure Cache for Redis"
  value       = azurerm_redis_cache.main.hostname
}

output "redis_port" {
  description = "Puerto SSL del Redis"
  value       = azurerm_redis_cache.main.ssl_port
}

output "redis_primary_key" {
  description = "Primary access key del Redis"
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}