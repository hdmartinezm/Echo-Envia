# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
}

# Random password para MySQL
resource "random_password" "mysql_admin_password" {
  length  = 32
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Self-signed certificate para Application Gateway (si no se proporciona uno)
resource "tls_private_key" "app_gateway" {
  count     = var.ssl_certificate_path == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_gateway" {
  count           = var.ssl_certificate_path == "" ? 1 : 0
  private_key_pem = tls_private_key.app_gateway[0].private_key_pem

  subject {
    common_name  = "${var.project_name}-${var.environment}.azurewebsites.net"
    organization = var.project_name
  }

  validity_period_hours = 8760 # 1 año

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# Módulos
module "networking" {
  source = "./modules/networking"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  project_name                 = var.project_name
  environment                  = var.environment
  vnet_address_space           = var.vnet_address_space
  app_gateway_subnet_prefix    = var.app_gateway_subnet_prefix
  app_service_subnet_prefix    = var.app_service_subnet_prefix
  private_endpoint_subnet_prefix = var.private_endpoint_subnet_prefix
  tags                         = var.tags
}

module "security" {
  source = "./modules/security"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  environment         = var.environment
  tags                = var.tags

  # Secretos a almacenar
  mysql_admin_password = random_password.mysql_admin_password.result
  mysql_admin_username = var.mysql_admin_username
}

module "database" {
  source = "./modules/database"

  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  project_name                  = var.project_name
  environment                   = var.environment
  tags                          = var.tags

  mysql_sku_name                = var.mysql_sku_name
  mysql_version                 = var.mysql_version
  mysql_storage_gb              = var.mysql_storage_gb
  mysql_backup_retention_days   = var.mysql_backup_retention_days
  mysql_geo_redundant_backup    = var.mysql_geo_redundant_backup
  mysql_high_availability_mode  = var.mysql_high_availability_mode
  mysql_admin_username          = var.mysql_admin_username
  mysql_admin_password          = random_password.mysql_admin_password.result
  mysql_database_name           = var.mysql_database_name

  delegated_subnet_id           = module.networking.private_endpoint_subnet_id
  private_dns_zone_id           = module.networking.mysql_private_dns_zone_id
}

module "storage" {
  source = "./modules/storage"

  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  project_name                = var.project_name
  environment                 = var.environment
  tags                        = var.tags

  account_tier                = var.storage_account_tier
  account_replication_type    = var.storage_account_replication
  enable_private_endpoint     = var.enable_private_endpoints
  private_endpoint_subnet_id  = module.networking.private_endpoint_subnet_id
  private_dns_zone_ids        = module.networking.storage_private_dns_zone_ids
}

module "compute" {
  source = "./modules/compute"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  project_name              = var.project_name
  environment               = var.environment
  tags                      = var.tags

  app_service_plan_sku      = var.app_service_plan_sku
  app_service_instances     = var.app_service_instances
  app_service_subnet_id     = module.networking.app_service_subnet_id
  key_vault_id              = module.security.key_vault_id
  app_service_identity_id   = module.security.app_service_identity_id

  # Variables de entorno para las apps
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "NODE_ENV"                     = var.environment
    "KEY_VAULT_URL"                = module.security.key_vault_uri
    "DB_HOST"                      = module.database.mysql_fqdn
    "DB_PORT"                      = "3306"
    "DB_NAME"                      = var.mysql_database_name
    "DB_USER"                      = var.mysql_admin_username
    "STORAGE_ACCOUNT_NAME"         = module.storage.storage_account_name
  }
}

module "gateway" {
  source = "./modules/gateway"

  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  project_name                = var.project_name
  environment                 = var.environment
  tags                        = var.tags

  app_gateway_sku             = var.app_gateway_sku
  waf_mode                    = var.waf_mode
  app_gateway_subnet_id       = module.networking.app_gateway_subnet_id
  backend_fqdns               = module.compute.app_service_default_hostnames

  # Certificado SSL
  ssl_certificate_data        = var.ssl_certificate_path != "" ? filebase64(var.ssl_certificate_path) : base64encode(tls_self_signed_cert.app_gateway[0].cert_pem)
  ssl_certificate_password    = var.ssl_certificate_path != "" ? nonsensitive(var.ssl_certificate_password) : ""
}
