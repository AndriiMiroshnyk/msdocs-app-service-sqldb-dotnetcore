variable "certificate_name" {
  description = "App Service certificate resource name. Defaults to the web app name with a custom-tls suffix."
  type        = string
  default     = null
}

variable "certificate_password" {
  description = "Local PFX password. Empty for an unprotected PFX. Stored in Terraform state."
  type        = string
  sensitive   = true
  default     = ""
}

variable "hostname" {
  description = "Application custom hostname."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID."
  type        = string
}

variable "location" {
  description = "Region matching the App Service plan."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "service_plan_id" {
  description = "App Service plan ID."
  type        = string
}

variable "tls_certificate" {
  description = "Local PFX import settings and tenant-specific App Service resource provider principal object ID. PFX contents are stored in Terraform state."
  type = object({
    key_vault_certificate_name      = string
    pfx_file_path                   = string
    app_service_principal_object_id = string
  })
  nullable = false
}

variable "web_app_name" {
  description = "Web app name."
  type        = string
}
