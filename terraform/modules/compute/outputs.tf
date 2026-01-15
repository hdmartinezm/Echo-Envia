output "app_service_plan_id" {
  description = "ID del App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "app_service_ids" {
  description = "IDs de los App Services"
  value       = azurerm_linux_web_app.main[*].id
}

output "app_service_names" {
  description = "Nombres de los App Services"
  value       = azurerm_linux_web_app.main[*].name
}

output "app_service_default_hostnames" {
  description = "Hostnames por defecto de los App Services"
  value       = azurerm_linux_web_app.main[*].default_hostname
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation Key de Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection String de Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}
