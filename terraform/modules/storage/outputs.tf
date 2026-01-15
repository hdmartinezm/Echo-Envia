output "storage_account_id" {
  description = "ID del Storage Account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Nombre del Storage Account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Endpoint primario de Blob"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "Endpoint primario de File"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "primary_access_key" {
  description = "Primary Access Key"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}
