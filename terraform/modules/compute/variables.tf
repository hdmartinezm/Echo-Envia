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

variable "app_service_plan_sku" {
  description = "SKU del App Service Plan"
  type = object({
    tier     = string
    size     = string
    capacity = number
  })
}

variable "app_service_instances" {
  description = "Número de instancias de App Service"
  type        = number
}

variable "app_service_subnet_id" {
  description = "ID de la subnet para App Service"
  type        = string
}

variable "key_vault_id" {
  description = "ID del Key Vault"
  type        = string
}

variable "app_service_identity_id" {
  description = "ID de la Managed Identity"
  type        = string
}

variable "app_settings" {
  description = "Configuración de la aplicación"
  type        = map(string)
  default     = {}
}
