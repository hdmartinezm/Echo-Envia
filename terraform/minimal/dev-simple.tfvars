# Configuración SIMPLE para entorno de desarrollo
# Sin private endpoints ni Application Gateway para evitar bugs del provider

project_name = "envia"
environment  = "dev"
location     = "West US 2"

tags = {
  Environment = "Development"
  Project     = "Envia"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Networking - Solo lo básico
vnet_address_space             = ["10.0.0.0/16"]
app_gateway_subnet_prefix      = "10.0.1.0/24"
app_service_subnet_prefix      = "10.0.2.0/24"
private_endpoint_subnet_prefix = "10.0.3.0/24"

# App Service - Configuración básica
app_service_plan_sku = {
  tier     = "Basic"
  size     = "B1"
  capacity = 1
}

app_service_instances = 1

# Database - Configuración básica sin VNet
mysql_sku_name                 = "B_Standard_B1s"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 20
mysql_backup_retention_days    = 7
mysql_geo_redundant_backup     = false
mysql_high_availability_mode   = "Disabled"
mysql_admin_username           = "enviaadmin"
mysql_database_name            = "enviadb"

# Application Gateway - Configuración básica
app_gateway_sku = {
  name     = "Standard_v2"
  tier     = "Standard_v2"
  capacity = 1
}

waf_mode = "Detection"

# Storage
storage_account_tier        = "Standard"
storage_account_replication = "LRS"

# Security - DESHABILITAR private endpoints para evitar bugs
enable_private_endpoints = false
allowed_ip_ranges        = []