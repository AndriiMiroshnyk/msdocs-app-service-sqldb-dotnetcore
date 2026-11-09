resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.web_app_name}-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
}

resource "azurerm_application_insights" "this" {
  name                = var.application_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.this.id
  retention_in_days   = 90
}

resource "azurerm_monitor_action_group" "smart_detection" {
  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "SmartDetect"
  location            = "global"
  enabled             = true

  arm_role_receiver {
    name                    = "Monitoring Contributor"
    role_id                 = "749f88d5-cbae-40b8-bcfc-e573ddc772fa"
    use_common_alert_schema = true
  }

  arm_role_receiver {
    name                    = "Monitoring Reader"
    role_id                 = "43d0d8ad-25c7-4714-9337-8ba259a9fe05"
    use_common_alert_schema = true
  }
}

resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.sku_name
  worker_count        = 1
}

resource "azurerm_linux_web_app" "this" {
  webdeploy_publish_basic_authentication_enabled = false
  ftp_publish_basic_authentication_enabled       = false
  name                                           = var.web_app_name
  resource_group_name                            = var.resource_group_name
  location                                       = var.location
  service_plan_id                                = azurerm_service_plan.this.id
  https_only                                     = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  app_settings                                   = local.app_settings

  connection_string {
    name  = "AZURE_SQL_DEFAULTCONNECTOR_CONNECTIONSTRING"
    type  = "SQLAzure"
    value = local.sql_connection_string
  }

  sticky_settings {
    connection_string_names = ["AZURE_SQL_DEFAULTCONNECTOR_CONNECTIONSTRING"]
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    vnet_route_all_enabled  = true
    always_on               = false
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    ftps_state              = "FtpsOnly"

    application_stack {
      dotnet_version = var.dotnet_version
    }
  }
}

resource "azurerm_linux_web_app_slot" "staging" {
  webdeploy_publish_basic_authentication_enabled = false
  ftp_publish_basic_authentication_enabled       = false
  name                                           = var.staging_slot_name
  app_service_id                                 = azurerm_linux_web_app.this.id
  https_only                                     = true
  virtual_network_subnet_id                      = var.integration_subnet_id
  app_settings                                   = local.app_settings

  connection_string {
    name  = "AZURE_SQL_DEFAULTCONNECTOR_CONNECTIONSTRING"
    type  = "SQLAzure"
    value = local.sql_connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    vnet_route_all_enabled  = true
    always_on               = false
    minimum_tls_version     = "1.2"
    scm_minimum_tls_version = "1.2"
    ftps_state              = "FtpsOnly"

    application_stack {
      dotnet_version = var.dotnet_version
    }
  }
}
