variable "action_group_name" {
  description = "Smart Detection action group name."
  type        = string
}

variable "application_insights_name" {
  description = "Application Insights resource name."
  type        = string
}

variable "dotnet_version" {
  description = ".NET runtime version for app and staging."
  type        = string
  default     = "10.0"
}

variable "integration_subnet_id" {
  description = "Subnet delegated to App Service for app and slot integration."
  type        = string
}

variable "location" {
  description = "Region for App Service and Application Insights."
  type        = string
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days. Application Insights uses 90 days."
  type        = number
  default     = 30
}

variable "resource_group_name" {
  description = "Resource group for App Service and Application Insights."
  type        = string
}

variable "service_plan_name" {
  description = "Linux App Service plan name."
  type        = string
}

variable "sku_name" {
  description = "Standard or Premium App Service SKU supporting staging slots."
  type        = string
}

variable "sql_database_name" {
  description = "SQL database name."
  type        = string
}

variable "sql_server_fqdn" {
  description = "SQL server hostname."
  type        = string
}

variable "staging_slot_name" {
  description = "Deployment slot name."
  type        = string
  default     = "staging"
}

variable "web_app_name" {
  description = "Globally unique Linux web app name."
  type        = string
}
