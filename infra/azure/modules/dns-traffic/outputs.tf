output "custom_hostname" {
  description = "Application custom hostname."
  value       = var.custom_domain == null ? null : "${var.custom_domain.record_name}.${var.custom_domain.zone_name}"
}

output "name_servers" {
  description = "Public DNS zone name servers."
  value       = try(azurerm_dns_zone.this[0].name_servers, [])
}

output "traffic_manager_hostname" {
  description = "Traffic Manager DNS hostname."
  value       = azurerm_traffic_manager_profile.this.fqdn
}
