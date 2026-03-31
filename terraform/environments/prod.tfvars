# Echo-Envia - Configuración para Producción
# Entorno de producción con alta disponibilidad y máxima seguridad

project_name = "echo-envia"
environment  = "prod"
location     = "East US"

tags = {
  Environment = "Production"
  Project     = "Echo-Envia"
  Owner       = "Echo Technologies"
  ManagedBy   = "Terraform"
  Solution    = "Shipping Platform"
  CostCenter  = "Engineering"
  Team        = "DevOps"
  Criticality = "High"
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

# Database - Configuración de producción con HA completa
mysql_sku_name                 = "GP_Standard_D4ds_v4"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 200
mysql_backup_retention_days    = 35
mysql_geo_redundant_backup     = true
mysql_high_availability_mode   = "ZoneRedundant"
mysql_admin_username           = "echoadmin"
mysql_database_name            = "echo_envia_db"

# Application Gateway - Configuración de producción
app_gateway_sku = {
  name     = "WAF_v2"
  tier     = "WAF_v2"
  capacity = 3
}

waf_mode = "Prevention"

# Storage - Con geo-redundancia y zona redundante
storage_account_tier        = "Standard"
storage_account_replication = "GZRS"

# Security
enable_private_endpoints = true
allowed_ip_ranges        = []