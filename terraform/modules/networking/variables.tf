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

variable "vnet_address_space" {
  description = "Espacio de direcciones de la VNet"
  type        = list(string)
}

variable "app_gateway_subnet_prefix" {
  description = "Prefijo de subnet para Application Gateway"
  type        = string
}

variable "app_service_subnet_prefix" {
  description = "Prefijo de subnet para App Service"
  type        = string
}

variable "private_endpoint_subnet_prefix" {
  description = "Prefijo de subnet para Private Endpoints"
  type        = string
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}
