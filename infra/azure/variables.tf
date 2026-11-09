variable "action_group_name" {
  description = "Smart Detection action group name."
  type        = string
}

variable "application_insights_name" {
  description = "Application Insights resource name."
  type        = string
}

variable "certificate_name" {
  description = "App Service certificate resource name. Defaults to the web app name with a custom-tls suffix."
  type        = string
  default     = null
}

variable "certificate_operator_object_id" {
  description = "Certificate operator object ID. Defaults to the authenticated Terraform identity when TLS import settings are supplied."
  type        = string
  default     = null
}

variable "certificate_password" {
  description = "Local PFX password, supplied through TF_VAR_certificate_password. Empty for an unprotected PFX. Stored in Terraform state."
  type        = string
  sensitive   = true
  default     = ""
}

variable "custom_domain" {
  description = "Optional public DNS zone, hostname binding and local PFX import into Key Vault for custom-domain TLS."
  type = object({
    zone_name      = string
    record_name    = optional(string, "www")
    enable_binding = optional(bool, false)
    tls_certificate = optional(object({
      key_vault_certificate_name      = string
      pfx_file_path                   = string
      app_service_principal_object_id = string
    }))
  })
  default = null
}

variable "dotnet_version" {
  description = ".NET runtime version for the web app and staging slot."
  type        = string
  default     = "10.0"
}

variable "integration_subnet_cidr" {
  description = "App Service integration subnet IPv4 range."
  type        = string
  default     = "10.0.1.0/24"
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name, at most 24 characters."
  type        = string
}

variable "location" {
  description = "Azure region for the deployment."
  type        = string
  default     = "canadacentral"
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days; Application Insights uses 90 days."
  type        = number
  default     = 30
}

variable "operator_ipv4_cidrs" {
  description = "IPv4 CIDRs permitted through the Key Vault firewall for certificate management."
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_cidr" {
  description = "Private endpoint subnet IPv4 range."
  type        = string
  default     = "10.0.2.0/24"
}

variable "resource_group_name" {
  description = "Resource group name for this deployment."
  type        = string
}

variable "service_plan_name" {
  description = "Linux App Service plan name."
  type        = string
}

variable "service_plan_sku_name" {
  description = "App Service plan SKU. P0v4 is the Premium default and supports staging slots."
  type        = string
  default     = "P0v4"
}

variable "sql_database_name" {
  description = "SQL application database name."
  type        = string
}

variable "sql_database_sku_name" {
  description = "Azure SQL database SKU. GP_Gen5_2 provides 2 vCores."
  type        = string
  default     = "GP_Gen5_2"
}

variable "sql_entra_admin_login_name" {
  description = "Display name of the Microsoft Entra administrator."
  type        = string
}

variable "sql_entra_admin_object_id" {
  description = "Object ID of the Microsoft Entra administrator."
  type        = string
}

variable "sql_server_name" {
  description = "Globally unique Azure SQL server name."
  type        = string
}

variable "staging_slot_name" {
  description = "Name of the deployment slot."
  type        = string
  default     = "staging"
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "traffic_manager_endpoint_name" {
  description = "Traffic Manager Azure endpoint name."
  type        = string
}

variable "traffic_manager_name" {
  description = "Traffic Manager profile name and globally unique trafficmanager.net DNS label."
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual network IPv4 address range."
  type        = string
  default     = "10.0.0.0/16"
}

variable "web_app_name" {
  description = "Globally unique web app name."
  type        = string
}
