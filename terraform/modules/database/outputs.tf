output "mysql_server_id" {
  description = "ID del MySQL Server"
  value       = azurerm_mysql_flexible_server.main.id
}

output "mysql_server_name" {
  description = "Nombre del MySQL Server"
  value       = azurerm_mysql_flexible_server.main.name
}

output "mysql_fqdn" {
  description = "FQDN del MySQL Server"
  value       = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_database_name" {
  description = "Nombre de la base de datos"
  value       = azurerm_mysql_flexible_database.main.name
}
