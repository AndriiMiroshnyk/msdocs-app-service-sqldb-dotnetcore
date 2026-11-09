output "database_name" {
  description = "Application database name."
  value       = azurerm_mssql_database.this.name
}

output "server_fqdn" {
  description = "SQL server hostname."
  value       = azurerm_mssql_server.this.fully_qualified_domain_name
}
