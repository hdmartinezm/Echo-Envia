# Configuración para entorno de producción

project_name = "envia"
environment  = "prod"
location     = "East US"

tags = {
  Environment = "Production"
  Project     = "Envia"
  ManagedBy   = "Terraform"
  CostCenter  = "Operations"
}

# Networking
vnet_address_space             = ["10.2.0.0/16"]
app_gateway_subnet_prefix      = "10.2.1.0/24"
app_service_subnet_prefix      = "10.2.2.0/24"
private_endpoint_subnet_prefix = "10.2.3.0/24"

# App Service - Configuración de producción
app_service_plan_sku = {
  tier     = "PremiumV3"
  size     = "P2v3"
  capacity = 3
}

app_service_instances = 3

# Database - Configuración completa con HA
mysql_sku_name                 = "GP_Standard_D2ds_v4"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 100
mysql_backup_retention_days    = 35
mysql_geo_redundant_backup     = true
mysql_high_availability_mode   = "ZoneRedundant"
mysql_admin_username           = "enviaadmin"
mysql_database_name            = "enviadb"

# Application Gateway - Configuración de producción
app_gateway_sku = {
  name     = "WAF_v2"
  tier     = "WAF_v2"
  capacity = 3
}

waf_mode = "Prevention"

# Storage - Con geo-redundancia
storage_account_tier        = "Standard"
storage_account_replication = "GZRS"

# Security
enable_private_endpoints = true
allowed_ip_ranges        = []
