output "custom_domain_verification_id" {
  description = "Verification token for custom-domain TXT records."
  value       = azurerm_linux_web_app.this.custom_domain_verification_id
  sensitive   = true
}

output "service_plan_id" {
  description = "Plan ID for Key Vault certificate integration."
  value       = azurerm_service_plan.this.id
}

output "staging_url" {
  description = "Default HTTPS URL for the staging slot."
  value       = "https://${azurerm_linux_web_app_slot.staging.default_hostname}/"
}

output "web_app_id" {
  description = "Web app ID."
  value       = azurerm_linux_web_app.this.id
}

output "web_app_name" {
  description = "Web app name."
  value       = azurerm_linux_web_app.this.name
}

output "web_app_url" {
  description = "Default HTTPS URL for the web app."
  value       = "https://${azurerm_linux_web_app.this.default_hostname}/"
}
