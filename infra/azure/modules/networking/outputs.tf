output "integration_subnet_id" {
  description = "Subnet ID for web app and slot VNet integration."
  value       = azurerm_subnet.integration.id
}

output "private_dns_zone_ids" {
  description = "Private DNS zone IDs keyed by sql and key_vault."
  value       = { for key, zone in azurerm_private_dns_zone.this : key => zone.id }
}

output "private_endpoint_subnet_id" {
  description = "Subnet ID for SQL and Key Vault private endpoints."
  value       = azurerm_subnet.private_endpoints.id
}
