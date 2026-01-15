# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "${var.app_service_plan_sku.tier}_${var.app_service_plan_sku.size}"
  worker_count        = var.app_service_plan_sku.capacity

  tags = var.tags
}

# App Services
resource "azurerm_linux_web_app" "main" {
  count               = var.app_service_instances
  name                = "app-${var.project_name}-${var.environment}-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id

  virtual_network_subnet_id = var.app_service_subnet_id

  https_only = true

  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_service_identity_id]
  }

  site_config {
    always_on         = true
    ftps_state        = "Disabled"
    minimum_tls_version = "1.2"
    http2_enabled     = true

    application_stack {
      node_version = "18-lts"
    }

    health_check_path = "/health"
    
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = merge(
    var.app_settings,
    {
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
      "WEBSITE_HTTPLOGGING_RETENTION_DAYS"  = "7"
      "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.main.instrumentation_key
      "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    }
  )

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }

    application_logs {
      file_system_level = "Information"
    }
  }

  tags = var.tags
}

# Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "Node.JS"

  tags = var.tags
}
