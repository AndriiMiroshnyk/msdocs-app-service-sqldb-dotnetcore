output "custom_domain" {
  description = "Custom hostname and public DNS name servers for registrar delegation."
  value = {
    hostname     = module.dns_traffic.custom_hostname
    name_servers = module.dns_traffic.name_servers
  }
}

output "database" {
  description = "SQL server hostname and application database name."
  value = {
    server_fqdn   = module.sql.server_fqdn
    database_name = module.sql.database_name
  }
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.key_vault.name
}

output "resource_group_name" {
  description = "Resource group name."
  value       = module.resource_group.name
}

output "staging_url" {
  description = "Default HTTPS URL for the staging slot."
  value       = module.app_service.staging_url
}

output "traffic_manager_hostname" {
  description = "Traffic Manager DNS hostname."
  value       = module.dns_traffic.traffic_manager_hostname
}

output "web_app_url" {
  description = "Default HTTPS URL for the web app."
  value       = module.app_service.web_app_url
}
