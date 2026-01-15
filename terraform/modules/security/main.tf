# Data source para obtener el tenant ID y client ID actual
data "azurerm_client_config" "current" {}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.environment}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  # Usar access policies en lugar de RBAC para evitar problemas de permisos
  enable_rbac_authorization = false

  # Access policy para el Service Principal actual
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge"
    ]
  }

  network_acls {
    default_action = "Allow"  # Cambiar a Allow para dev
    bypass         = "AzureServices"
  }

  tags = var.tags
}

# Secreto: MySQL Admin Password
resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  value        = var.mysql_admin_password
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
}

# Secreto: MySQL Admin Username
resource "azurerm_key_vault_secret" "mysql_username" {
  name         = "mysql-admin-username"
  value        = var.mysql_admin_username
  key_vault_id = azurerm_key_vault.main.id
  tags         = var.tags
}

# User Assigned Managed Identity para App Services
resource "azurerm_user_assigned_identity" "app_service" {
  name                = "id-appservice-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Access policy para que App Service pueda leer secretos
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_service.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
