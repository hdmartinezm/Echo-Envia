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

variable "app_gateway_sku" {
  description = "SKU del Application Gateway"
  type = object({
    name     = string
    tier     = string
    capacity = number
  })
}

variable "waf_mode" {
  description = "Modo del WAF"
  type        = string
}

variable "app_gateway_subnet_id" {
  description = "ID de la subnet del Application Gateway"
  type        = string
}

variable "backend_fqdns" {
  description = "FQDNs de los backends"
  type        = list(string)
}

variable "ssl_certificate_data" {
  description = "Datos del certificado SSL en base64"
  type        = string
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "Contraseña del certificado SSL"
  type        = string
  sensitive   = true
}
