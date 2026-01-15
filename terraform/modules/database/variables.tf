variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}

variable "mysql_sku_name" {
  description = "SKU del MySQL Flexible Server"
  type        = string
}

variable "mysql_version" {
  description = "Versión de MySQL"
  type        = string
}

variable "mysql_storage_gb" {
  description = "Tamaño de almacenamiento en GB"
  type        = number
}

variable "mysql_backup_retention_days" {
  description = "Días de retención de backups"
  type        = number
}

variable "mysql_geo_redundant_backup" {
  description = "Habilitar backup geo-redundante"
  type        = bool
}

variable "mysql_high_availability_mode" {
  description = "Modo de alta disponibilidad"
  type        = string
}

variable "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_admin_password" {
  description = "Contraseña del administrador de MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_database_name" {
  description = "Nombre de la base de datos"
  type        = string
}

variable "delegated_subnet_id" {
  description = "ID de la subnet delegada"
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID de la Private DNS Zone"
  type        = string
}
