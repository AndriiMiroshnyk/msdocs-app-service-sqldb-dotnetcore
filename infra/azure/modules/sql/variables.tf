variable "database_name" {
  description = "SQL application database name."
  type        = string
}

variable "database_sku_name" {
  description = "Azure SQL database SKU. GP_Gen5_2 provides 2 vCores."
  type        = string
  default     = "GP_Gen5_2"
}

variable "entra_admin_login_name" {
  description = "Display name of the Microsoft Entra administrator."
  type        = string
}

variable "entra_admin_object_id" {
  description = "Object ID of the Entra administrator user or group."
  type        = string
}

variable "location" {
  description = "SQL server region."
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.database.windows.net."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the SQL private endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for SQL resources."
  type        = string
}

variable "server_name" {
  description = "Globally unique SQL server name."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}
