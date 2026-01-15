# Outputs para la configuración mínima

output "resource_group_name" {
  description = "Nombre del Resource Group"
  value       = azurerm_resource_group.main.name
}

output "app_service_url" {
  description = "URL del App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "mysql_server_fqdn" {
  description = "FQDN del servidor MySQL"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_database_name" {
  description = "Nombre de la base de datos MySQL"
  value       = azurerm_mysql_flexible_database.main.name
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = azurerm_storage_account.main.name
}

output "deployment_summary" {
  description = "Resumen del despliegue"
  value = {
    resource_group    = azurerm_resource_group.main.name
    app_service      = azurerm_linux_web_app.main.name
    mysql_server     = azurerm_mysql_flexible_server.main.name
    storage_account  = azurerm_storage_account.main.name
    location         = var.location
    environment      = var.environment
  }
}