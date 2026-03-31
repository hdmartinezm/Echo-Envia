# Echo-Envia - Configuración para Desarrollo
# Entorno optimizado para desarrollo y pruebas

project_name = "echo-envia"
environment  = "dev"
location     = "Central US"  # Región con cuota disponible

tags = {
  Environment = "Development"
  Project     = "Echo-Envia"
  Owner       = "Echo Technologies"
  ManagedBy   = "Terraform"
  Solution    = "Shipping Platform"
  CostCenter  = "Engineering"
  Team        = "DevOps"
}

# Networking
vnet_address_space             = ["10.0.0.0/16"]
app_gateway_subnet_prefix      = "10.0.1.0/24"
app_service_subnet_prefix      = "10.0.2.0/24"
private_endpoint_subnet_prefix = "10.0.3.0/24"

# App Service - Configuración robusta para desarrollo con alta disponibilidad
app_service_plan_sku = {
  tier     = "PremiumV3"
  size     = "P1v3"
  capacity = 2  # Múltiples instancias para alta disponibilidad
}

app_service_instances = 2  # Múltiples instancias para alta disponibilidad

# Database - Configuración básica para desarrollo
mysql_sku_name                 = "GP_Standard_D2ds_v4"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 50
mysql_backup_retention_days    = 7
mysql_geo_redundant_backup     = false
mysql_high_availability_mode   = "Disabled"
mysql_admin_username           = "echoadmin"
mysql_database_name            = "envia_delivery"

# Application Gateway - Configuración básica
app_gateway_sku = {
  name     = "WAF_v2"
  tier     = "WAF_v2"
  capacity = 1
}

waf_mode = "Detection"

# Storage
storage_account_tier        = "Standard"
storage_account_replication = "LRS"

# Security
enable_private_endpoints = true
allowed_ip_ranges        = []

# Azure Front Door
front_door_sku           = "Standard_AzureFrontDoor"
front_door_custom_domain = ""

# Private Endpoints
enable_mysql_private_endpoint    = true
enable_storage_private_endpoint  = true
enable_keyvault_private_endpoint = true

# MySQL High Availability
enable_mysql_replica    = true
mysql_replica_location  = "West US 2"