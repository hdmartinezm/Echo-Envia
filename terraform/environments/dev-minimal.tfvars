# Configuración MÍNIMA para entorno de desarrollo
# Para suscripciones con limitaciones de cuota

project_name = "envia"
environment  = "dev"
location     = "West US"  # Cambiar región

tags = {
  Environment = "Development"
  Project     = "Envia"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Networking - Configuración mínima
vnet_address_space             = ["10.0.0.0/16"]
app_gateway_subnet_prefix      = "10.0.1.0/24"
app_service_subnet_prefix      = "10.0.2.0/24"
private_endpoint_subnet_prefix = "10.0.3.0/24"

# App Service - Usar Free tier (F1)
app_service_plan_sku = {
  tier     = "Free"
  size     = "F1"
  capacity = 1
}

app_service_instances = 1  # Solo 1 instancia en Free

# Database - Configuración más básica
mysql_sku_name                 = "B_Standard_B1s"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 20
mysql_backup_retention_days    = 7
mysql_geo_redundant_backup     = false
mysql_high_availability_mode   = "Disabled"
mysql_admin_username           = "enviaadmin"
mysql_database_name            = "enviadb"

# Application Gateway - Deshabilitar para dev minimal
app_gateway_sku = {
  name     = "Standard_v2"
  tier     = "Standard_v2"
  capacity = 1
}

waf_mode = "Detection"

# Storage
storage_account_tier        = "Standard"
storage_account_replication = "LRS"

# Security - Deshabilitar private endpoints
enable_private_endpoints = false
allowed_ip_ranges        = []
