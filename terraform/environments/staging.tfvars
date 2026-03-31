# Echo-Envia - Configuración para Staging
# Entorno de pre-producción con configuración similar a producción

project_name = "echo-envia"
environment  = "staging"
location     = "East US"

tags = {
  Environment = "Staging"
  Project     = "Echo-Envia"
  Owner       = "Echo Technologies"
  ManagedBy   = "Terraform"
  Solution    = "Shipping Platform"
  CostCenter  = "Engineering"
  Team        = "DevOps"
}

# Networking
vnet_address_space             = ["10.1.0.0/16"]
app_gateway_subnet_prefix      = "10.1.1.0/24"
app_service_subnet_prefix      = "10.1.2.0/24"
private_endpoint_subnet_prefix = "10.1.3.0/24"

# App Service - Configuración intermedia
app_service_plan_sku = {
  tier     = "PremiumV3"
  size     = "P1v3"
  capacity = 2
}

app_service_instances = 2

# Database - Configuración intermedia con HA
mysql_sku_name                 = "GP_Standard_D2ds_v4"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 100
mysql_backup_retention_days    = 14
mysql_geo_redundant_backup     = true
mysql_high_availability_mode   = "SameZone"
mysql_admin_username           = "echoadmin"
mysql_database_name            = "echo_envia_db"

# Application Gateway - Configuración intermedia
app_gateway_sku = {
  name     = "WAF_v2"
  tier     = "WAF_v2"
  capacity = 2
}

waf_mode = "Prevention"

# Storage - Con geo-redundancia
storage_account_tier        = "Standard"
storage_account_replication = "GRS"

# Security
enable_private_endpoints = true
allowed_ip_ranges        = []