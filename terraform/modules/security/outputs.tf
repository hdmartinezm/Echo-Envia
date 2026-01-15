output "key_vault_id" {
  description = "ID del Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "Nombre del Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI del Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "app_service_identity_id" {
  description = "ID de la Managed Identity para App Services"
  value       = azurerm_user_assigned_identity.app_service.id
}

output "app_service_identity_principal_id" {
  description = "Principal ID de la Managed Identity"
  value       = azurerm_user_assigned_identity.app_service.principal_id
}

output "app_service_identity_client_id" {
  description = "Client ID de la Managed Identity"
  value       = azurerm_user_assigned_identity.app_service.client_id
}
