# Echo-Envia Infrastructure - Configuración Simplificada pero Robusta
# Evita bugs del provider AzureRM manteniendo seguridad y alta disponibilidad

# Resource Group existente (importado)
data "azurerm_resource_group" "main" {
  name = "rg_delivery2"
}

# Random password para MySQL
resource "random_password" "mysql_admin_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Networking"
  })
}

# Subnet para App Services
resource "azurerm_subnet" "app_service" {
  name                 = "snet-appservice"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.app_service_subnet_prefix]

  delegation {
    name = "app-service-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Subnet para Application Gateway
resource "azurerm_subnet" "app_gateway" {
  name                 = "snet-appgateway"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.app_gateway_subnet_prefix]
}

# Subnet para Private Endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "snet-privateendpoints"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_endpoint_subnet_prefix]
}

# Network Security Group para App Services
resource "azurerm_network_security_group" "app_service" {
  name                = "nsg-appservice-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowAppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = var.app_gateway_subnet_prefix
    destination_address_prefix = "*"
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Networking"
  })
}

# Asociar NSG con subnet
resource "azurerm_subnet_network_security_group_association" "app_service" {
  subnet_id                 = azurerm_subnet.app_service.id
  network_security_group_id = azurerm_network_security_group.app_service.id
}

# Storage Account
resource "azurerm_storage_account" "main" {
  name                            = "st${replace(var.project_name, "-", "")}${var.environment}${random_id.storage_suffix.hex}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Storage"
  })
}

resource "random_id" "storage_suffix" {
  byte_length = 4
}

resource "random_id" "mysql_suffix" {
  byte_length = 4
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                = "kv${replace(var.project_name, "-", "")}${var.environment}${random_id.kv_suffix.hex}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"
    ]
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })

  lifecycle {
    ignore_changes = [access_policy]
  }
}

resource "random_id" "kv_suffix" {
  byte_length = 4
}

data "azurerm_client_config" "current" {}

# Almacenar credenciales en Key Vault
resource "azurerm_key_vault_secret" "mysql_username" {
  name         = "mysql-admin-username"
  value        = var.mysql_admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin_password.result
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

# MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "main" {
  name                   = "mysql-${var.project_name}-${var.environment}-${random_id.mysql_suffix.hex}"
  resource_group_name    = data.azurerm_resource_group.main.name
  location               = data.azurerm_resource_group.main.location
  administrator_login    = var.mysql_admin_username
  administrator_password = random_password.mysql_admin_password.result

  sku_name                     = var.mysql_sku_name
  version                      = var.mysql_version
  backup_retention_days        = var.mysql_backup_retention_days
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup

  storage {
    size_gb = var.mysql_storage_gb
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Database"
  })

  lifecycle {
    ignore_changes = [
      zone,
      administrator_login,
      administrator_password,
      geo_redundant_backup_enabled,
      high_availability,
      storage,
    ]
  }
}

# Storage Account para Azure Files (ZRS, Hot) — almacenamiento persistente compartido
resource "azurerm_storage_account" "files" {
  name                            = "stechoenviafileszrs"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Storage"
  })
}

# File Share 100GB para /var/www/html/storage/app
resource "azurerm_storage_share" "files" {
  name               = "envia-storage"
  storage_account_name = azurerm_storage_account.files.name
  quota              = 100
  access_tier        = "Hot"
}

# Nota: directorios Laravel (app/, app/public/) creados manualmente en el File Share
# vía az storage directory create (no existe recurso azurerm_storage_directory)

# Firewall rule para permitir servicios de Azure
resource "azurerm_mysql_flexible_server_firewall_rule" "azure_services" {
  name                = "AllowAzureServices"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Firewall rule para Victor (laptop secundaria)
resource "azurerm_mysql_flexible_server_firewall_rule" "victor_2" {
  name                = "dev-laptop-victor-2"
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = "190.62.18.133"
  end_ip_address      = "190.62.18.133"
}

# Base de datos
resource "azurerm_mysql_flexible_database" "main" {
  name                = var.mysql_database_name
  resource_group_name = data.azurerm_resource_group.main.name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"

  lifecycle {
    ignore_changes = [name, charset, collation]
  }
}

# App Service Plan con alta disponibilidad
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku.size
  worker_count        = var.app_service_instances

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Compute"
  })
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}${random_id.acr_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Container"
  })
}

resource "random_id" "acr_suffix" {
  byte_length = 4
}

# Almacenar credenciales de ACR en Key Vault
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = azurerm_container_registry.main.admin_username
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = azurerm_container_registry.main.admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

# Managed Identity para App Services
resource "azurerm_user_assigned_identity" "app_service" {
  name                = "id-appservice-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

# Política de acceso al Key Vault para la Managed Identity
resource "azurerm_key_vault_access_policy" "app_service" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app_service.principal_id

  secret_permissions = ["Get", "List"]
}

# App Services con alta disponibilidad (2 instancias) - Usando Docker
resource "azurerm_linux_web_app" "main" {
  count               = var.app_service_instances
  name                = "app-${var.project_name}-${var.environment}-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  virtual_network_subnet_id = azurerm_subnet.app_service.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_service.id]
  }

  site_config {
    always_on = true

    application_stack {
      docker_image_name        = "echo-envia-app:75"
      docker_registry_url      = "https://${azurerm_container_registry.main.login_server}"
      docker_registry_username = azurerm_container_registry.main.admin_username
      docker_registry_password = azurerm_container_registry.main.admin_password
    }

    health_check_path = "/healthz"
  }

  app_settings = {
    # Docker (DOCKER_REGISTRY_SERVER_* son gestionados por application_stack en site_config)
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "80"
    "WEBSITES_CONTAINER_START_TIME_LIMIT" = "1800"

    # Laravel
    "APP_ENV"    = var.environment
    "APP_DEBUG"  = "false"
    "APP_KEY"    = var.app_key
    "APP_NAME"   = "Envia Admin Panel"
    "APP_URL"    = "https://delivery2.envia.com.gt"
    "NODE_ENV"   = var.environment
    "KEY_VAULT_URL" = azurerm_key_vault.main.vault_uri

    # Logging
    "LOG_CHANNEL" = "stderr"
    "LOG_LEVEL"   = "debug"

    # Database
    "DB_CONNECTION"     = "mysql"
    "DB_HOST"           = azurerm_mysql_flexible_server.main.fqdn
    "DB_PORT"           = "3306"
    "DB_DATABASE"       = var.mysql_database_name
    "DB_USERNAME"       = var.mysql_admin_username
    "DB_PASSWORD"       = var.db_password
    "MYSQL_ATTR_SSL_CA" = "/etc/ssl/cert.pem"

    # Redis (ssl:// prefix requerido para phpredis con TLS)
    "REDIS_HOST"     = "ssl://${azurerm_redis_cache.main.hostname}"
    "REDIS_PORT"     = "6380"
    "REDIS_PASSWORD" = azurerm_redis_cache.main.primary_access_key
    "REDIS_CLIENT"   = "phpredis"
    "REDIS_DB"       = "0"
    "REDIS_CACHE_DB" = "1"
    "REDIS_QUEUE_DB" = "0"

    # Cache, Session, Queue
    "CACHE_STORE"           = "redis"
    "SESSION_DRIVER"        = "database"
    "SESSION_SECURE_COOKIE" = "false"
    "QUEUE_CONNECTION"      = "redis"

    # Migrations
    "RUN_MIGRATIONS" = "false"

    # Storage
    "STORAGE_ACCOUNT_NAME" = azurerm_storage_account.files.name
    "PROJECT_NAME"         = var.project_name
    "COMPANY_NAME"         = "Echo Technologies"
  }

  storage_account {
    name         = "envia-files"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.files.name
    share_name   = azurerm_storage_share.files.name
    access_key   = azurerm_storage_account.files.primary_access_key
    mount_path   = "/var/www/html/storage/app"
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Compute"
    Instance  = count.index + 1
  })

  depends_on = [
    azurerm_mysql_flexible_database.main,
    azurerm_key_vault_access_policy.app_service,
    azurerm_container_registry.main
  ]
}

# Public IP para Application Gateway
resource "azurerm_public_ip" "app_gateway" {
  name                = "pip-appgw-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.project_name}-${var.environment}"

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Gateway"
  })
}

# Self-signed certificate para Application Gateway
resource "tls_private_key" "app_gateway" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "app_gateway" {
  private_key_pem = tls_private_key.app_gateway.private_key_pem

  subject {
    common_name  = "${var.project_name}-${var.environment}.azurewebsites.net"
    organization = "Echo-Envia"
  }

  validity_period_hours = 8760 # 1 año

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# PKCS#12 certificate para Application Gateway
resource "pkcs12_from_pem" "app_gateway" {
  cert_pem        = tls_self_signed_cert.app_gateway.cert_pem
  private_key_pem = tls_private_key.app_gateway.private_key_pem
  password        = "EchoEnvia2024!"
}

# Application Gateway con WAF
resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  sku {
    name     = var.app_gateway_sku.name
    tier     = var.app_gateway_sku.tier
    capacity = var.app_gateway_sku.capacity
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.app_gateway.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-config"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name  = "backend-pool"
    fqdns = [for app in azurerm_linux_web_app.main : app.default_hostname]
  }

  backend_http_settings {
    name                                = "backend-http-settings"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "health-probe"
  }

  probe {
    name                                      = "health-probe"
    protocol                                  = "Http"
    path                                      = "/healthz"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-config"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = var.waf_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"

    disabled_rule_group {
      rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
      rules           = [920300, 920330]
    }
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101S"
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Gateway"
  })

  depends_on = [azurerm_linux_web_app.main]
}

# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "fd-${var.project_name}-${var.environment}"
  resource_group_name = data.azurerm_resource_group.main.name
  sku_name            = var.front_door_sku

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "CDN"
  })
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "fd-endpoint-${var.project_name}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "CDN"
  })
}

# Front Door Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "fd-origin-group-${var.project_name}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/healthz"
    request_type        = "HEAD"
    protocol            = "Http"
    interval_in_seconds = 100
  }
}

# Front Door Origins (App Services)
resource "azurerm_cdn_frontdoor_origin" "app_services" {
  count                         = length(azurerm_linux_web_app.main)
  name                          = "fd-origin-${var.project_name}-${var.environment}-${count.index + 1}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  enabled            = true
  host_name          = azurerm_linux_web_app.main[count.index].default_hostname
  http_port          = 80
  https_port         = 443
  origin_host_header = azurerm_linux_web_app.main[count.index].default_hostname
  priority           = 1
  weight             = 1000

  certificate_name_check_enabled = true
}

# Front Door Route
resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "fd-route-${var.project_name}-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [for origin in azurerm_cdn_frontdoor_origin.app_services : origin.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress = [
      "application/eot",
      "application/font",
      "application/font-sfnt",
      "application/javascript",
      "application/json",
      "application/opentype",
      "application/otf",
      "application/pkcs7-mime",
      "application/truetype",
      "application/ttf",
      "application/vnd.ms-fontobject",
      "application/xhtml+xml",
      "application/xml",
      "application/xml+rss",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/x-httpd-cgi",
      "application/x-javascript",
      "application/x-mpegurl",
      "application/x-opentype",
      "application/x-otf",
      "application/x-perl",
      "application/x-ttf",
      "font/eot",
      "font/ttf",
      "font/otf",
      "font/opentype",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/richtext",
      "text/tab-separated-values",
      "text/xml",
      "text/x-script",
      "text/x-component",
      "text/x-java-source"
    ]
  }
}

# Private DNS Zones para Private Endpoints
resource "azurerm_private_dns_zone" "mysql" {
  count               = var.enable_mysql_private_endpoint ? 1 : 0
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

resource "azurerm_private_dns_zone" "storage" {
  count               = var.enable_storage_private_endpoint ? 1 : 0
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

resource "azurerm_private_dns_zone" "keyvault" {
  count               = var.enable_keyvault_private_endpoint ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.main.name

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

# VNet Links para Private DNS Zones
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count                 = var.enable_mysql_private_endpoint ? 1 : 0
  name                  = "mysql-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  count                 = var.enable_storage_private_endpoint ? 1 : 0
  name                  = "storage-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  count                 = var.enable_keyvault_private_endpoint ? 1 : 0
  name                  = "keyvault-vnet-link"
  resource_group_name   = data.azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault[0].name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "DNS"
  })
}

# Private Endpoint para MySQL
resource "azurerm_private_endpoint" "mysql" {
  count               = var.enable_mysql_private_endpoint ? 1 : 0
  name                = "pe-mysql-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-mysql-${var.project_name}-${var.environment}"
    private_connection_resource_id = azurerm_mysql_flexible_server.main.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "mysql-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.mysql[0].id]
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })

  depends_on = [azurerm_private_dns_zone.mysql]
}

# Private Endpoint para Storage Account
resource "azurerm_private_endpoint" "storage" {
  count               = var.enable_storage_private_endpoint ? 1 : 0
  name                = "pe-storage-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-storage-${var.project_name}-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage[0].id]
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })

  depends_on = [azurerm_private_dns_zone.storage]
}

# Private Endpoint para Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  count               = var.enable_keyvault_private_endpoint ? 1 : 0
  name                = "pe-keyvault-${var.project_name}-${var.environment}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "psc-keyvault-${var.project_name}-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault[0].id]
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })

  depends_on = [azurerm_private_dns_zone.keyvault]
}

# MySQL Read Replica
resource "azurerm_mysql_flexible_server" "replica" {
  count               = var.enable_mysql_replica ? 1 : 0
  name                = "mysql-${var.project_name}-${var.environment}-replica-${random_id.mysql_suffix.hex}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = var.mysql_replica_location

  create_mode      = "Replica"
  source_server_id = azurerm_mysql_flexible_server.main.id

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Database"
    Role      = "Replica"
  })

  lifecycle {
    ignore_changes = [
      zone,
      geo_redundant_backup_enabled,
      source_server_id,
    ]
  }
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  name                = "redis-${var.project_name}-${var.environment}-${random_id.redis_suffix.hex}"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Cache"
  })
}

resource "random_id" "redis_suffix" {
  byte_length = 4
}

# Almacenar credenciales de Redis en Key Vault
resource "azurerm_key_vault_secret" "redis_host" {
  name         = "redis-host"
  value        = azurerm_redis_cache.main.hostname
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = azurerm_redis_cache.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_key_vault.main]

  tags = merge(var.tags, {
    Project   = "Echo-Envia"
    Component = "Security"
  })
}