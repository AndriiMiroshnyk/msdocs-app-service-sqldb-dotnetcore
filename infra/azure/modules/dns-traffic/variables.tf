variable "custom_domain" {
  description = "Optional public DNS zone and application record managed by this stack."
  type        = object({ zone_name = string, record_name = string })
  default     = null
}

variable "custom_domain_verification_id" {
  description = "App Service verification token used in the DNS TXT record."
  type        = string
}

variable "endpoint_name" {
  description = "Traffic Manager Azure endpoint name."
  type        = string
}

variable "profile_name" {
  description = "Traffic Manager profile name, also used for its globally unique DNS label."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for Traffic Manager and the optional DNS zone."
  type        = string
}

variable "web_app_id" {
  description = "Web app ID for the Azure endpoint."
  type        = string
}
