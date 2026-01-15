# Configuración para entorno de staging

project_name = "envia"
environment  = "staging"
location     = "East US"

tags = {
  Environment = "Staging"
  Project     = "Envia"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Networking
vnet_address_space             = ["10.1.0.0/16"]
app_gateway_subnet_prefix      = "10.1.1.0/24"
app_service_subnet_prefix      = "10.1.2.0/24"
private_endpoint_subnet_prefix = "10.1.3.0/24"

# App Service
app_service_plan_sku = {
  tier     = "PremiumV3"
  size     = "P1v3"
  capacity = 2
}

app_service_instances = 2

# Database - Con alta disponibilidad
mysql_sku_name                 = "B_Standard_B2s"
mysql_version                  = "8.0.21"
mysql_storage_gb               = 50
mysql_backup_retention_days    = 14
mysql_geo_redundant_backup     = true
mysql_high_availability_mode   = "SameZone"
mysql_admin_username           = "enviaadmin"
mysql_database_name            = "enviadb"

# Application Gateway
app_gateway_sku = {
  name     = "WAF_v2"
  tier     = "WAF_v2"
  capacity = 2
}

waf_mode = "Prevention"

# Storage
storage_account_tier        = "Standard"
storage_account_replication = "GRS"

# Security
enable_private_endpoints = true
allowed_ip_ranges        = []
