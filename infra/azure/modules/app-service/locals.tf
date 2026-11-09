locals {
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING       = azurerm_application_insights.this.connection_string
    ApplicationInsightsAgent_EXTENSION_VERSION  = "~3"
    XDT_MicrosoftApplicationInsights_Mode       = "recommended"
    XDT_MicrosoftApplicationInsights_PreemptSdk = "1"
  }
  sql_connection_string = "Server=tcp:${var.sql_server_fqdn},1433;Database=${var.sql_database_name};Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;"
}
