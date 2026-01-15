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

variable "account_tier" {
  description = "Tier del Storage Account"
  type        = string
}

variable "account_replication_type" {
  description = "Tipo de replicación"
  type        = string
}

variable "enable_private_endpoint" {
  description = "Habilitar Private Endpoint"
  type        = bool
}

variable "private_endpoint_subnet_id" {
  description = "ID de la subnet para Private Endpoints"
  type        = string
}

variable "private_dns_zone_ids" {
  description = "IDs de las Private DNS Zones"
  type = object({
    blob = string
    file = string
  })
}
