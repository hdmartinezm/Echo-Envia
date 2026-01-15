output "application_gateway_id" {
  description = "ID del Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "application_gateway_name" {
  description = "Nombre del Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "public_ip_address" {
  description = "Dirección IP pública"
  value       = azurerm_public_ip.main.ip_address
}

output "public_ip_fqdn" {
  description = "FQDN de la IP pública"
  value       = azurerm_public_ip.main.fqdn
}
