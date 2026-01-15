# Configuración MÍNIMA para evitar bugs del provider
# Solo recursos esenciales sin dependencias complejas

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Random password para MySQL
resource "random_password" "mysql_admin_password" {
  length  = 32
  special = true
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku.size
  worker_count        = var.app_service_plan_sku.capacity

  tags = var.tags
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false  # Para Basic tier
    
    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    "MYSQL_HOST"     = azurerm_mysql_flexible_server.main.fqdn
    "MYSQL_DATABASE" = azurerm_mysql_flexible_database.main.name
    "MYSQL_USERNAME" = var.mysql_admin_username
    "MYSQL_PASSWORD" = random_password.mysql_admin_password.result
  }

  tags = var.tags
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-${var.project_name}-${var.environment}"
  location               = azurerm_resource_group.main.location
  resource_group_name    = azurerm_resource_group.main.name
  administrator_login    = var.mysql_admin_username
  administrator_password = random_password.mysql_admin_password.result
  
  sku_name = var.mysql_sku_name
  version  = var.mysql_version

  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup

  storage {
    size_gb           = var.mysql_storage_gb
    auto_grow_enabled = true
  }

  tags = var.tags
}

# MySQL Database
resource "azurerm_mysql_flexible_database" "main" {
  name                = var.mysql_database_name
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# MySQL Firewall Rule - Allow Azure Services
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                     = lower(replace("st${var.project_name}${var.environment}${formatdate("MMDDhhmm", timestamp())}", "-", ""))
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  account_kind             = "StorageV2"

  tags = var.tags

  lifecycle {
    ignore_changes = [name]
  }
}

# Storage Container
resource "azurerm_storage_container" "app_data" {
  name                  = "app-data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}