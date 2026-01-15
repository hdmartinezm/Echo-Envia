variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "envia"
}

variable "environment" {
  description = "Entorno de despliegue (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "El entorno debe ser dev, staging o prod."
  }
}

variable "location" {
  description = "Región de Azure para los recursos"
  type        = string
  default     = "East US"
}

variable "tags" {
  description = "Tags comunes para todos los recursos"
  type        = map(string)
  default     = {}
}

# Networking
variable "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "app_gateway_subnet_prefix" {
  description = "Prefijo de subnet para Application Gateway"
  type        = string
  default     = "10.0.1.0/24"
}

variable "app_service_subnet_prefix" {
  description = "Prefijo de subnet para App Service"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_endpoint_subnet_prefix" {
  description = "Prefijo de subnet para Private Endpoints"
  type        = string
  default     = "10.0.3.0/24"
}

# App Service
variable "app_service_plan_sku" {
  description = "SKU del App Service Plan"
  type = object({
    tier     = string
    size     = string
    capacity = number
  })
  default = {
    tier     = "PremiumV3"
    size     = "P1v3"
    capacity = 2
  }
}

variable "app_service_instances" {
  description = "Número de instancias de App Service"
  type        = number
  default     = 2
}

# Database
variable "mysql_sku_name" {
  description = "SKU del MySQL Flexible Server"
  type        = string
  default     = "B_Standard_B2s"
}

variable "mysql_version" {
  description = "Versión de MySQL"
  type        = string
  default     = "8.0.21"
}

variable "mysql_storage_gb" {
  description = "Tamaño de almacenamiento en GB"
  type        = number
  default     = 100
}

variable "mysql_backup_retention_days" {
  description = "Días de retención de backups"
  type        = number
  default     = 7
}

variable "mysql_geo_redundant_backup" {
  description = "Habilitar backup geo-redundante"
  type        = bool
  default     = true
}

variable "mysql_high_availability_mode" {
  description = "Modo de alta disponibilidad (ZoneRedundant o SameZone)"
  type        = string
  default     = "ZoneRedundant"
}

variable "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  default     = "enviaadmin"
  sensitive   = true
}

variable "mysql_database_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "enviadb"
}

# Application Gateway
variable "app_gateway_sku" {
  description = "SKU del Application Gateway"
  type = object({
    name     = string
    tier     = string
    capacity = number
  })
  default = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }
}

variable "waf_mode" {
  description = "Modo del WAF (Detection o Prevention)"
  type        = string
  default     = "Prevention"
}

# Storage
variable "storage_account_tier" {
  description = "Tier del Storage Account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Tipo de replicación del Storage Account"
  type        = string
  default     = "LRS"
}

# Security
variable "allowed_ip_ranges" {
  description = "Rangos de IP permitidos para acceso administrativo"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoints" {
  description = "Habilitar Private Endpoints"
  type        = bool
  default     = true
}

variable "ssl_certificate_path" {
  description = "Ruta al certificado SSL (opcional, se generará uno self-signed si no se proporciona)"
  type        = string
  default     = ""
}

variable "ssl_certificate_password" {
  description = "Contraseña del certificado SSL"
  type        = string
  default     = ""
  sensitive   = true
}
