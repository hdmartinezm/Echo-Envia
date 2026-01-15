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

variable "mysql_admin_password" {
  description = "Contraseña del administrador de MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_admin_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  sensitive   = true
}
