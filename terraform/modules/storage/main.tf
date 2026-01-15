# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = lower(replace("st${var.project_name}${var.environment}${formatdate("MMDDhhmm", timestamp())}", "-", ""))
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true

  # Permitir acceso público para dev - cambiar a Deny en prod
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [name]  # Ignorar cambios en el nombre después de la creación
  }
}

# Blob Container para aplicación
resource "azurerm_storage_container" "app_data" {
  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Blob Container para backups
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File Share para configuración compartida
resource "azurerm_storage_share" "config" {
  name                 = "config"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 10
}

# Private Endpoint para Blob
resource "azurerm_private_endpoint" "blob" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-blob-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "blob-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.blob]
  }

  tags = var.tags
}

# Private Endpoint para File
resource "azurerm_private_endpoint" "file" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "pe-file-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-file"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }

  private_dns_zone_group {
    name                 = "file-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids.file]
  }

  tags = var.tags
}
