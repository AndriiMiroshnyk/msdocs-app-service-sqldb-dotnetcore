variable "certificate_operator_object_id" {
  description = "Object ID of the certificate operator."
  type        = string
  default     = null
}

variable "location" {
  description = "Key Vault region."
  type        = string
}

variable "name" {
  description = "Globally unique Key Vault name, at most 24 characters."
  type        = string
}

variable "operator_ipv4_cidrs" {
  description = "Public IPv4 CIDRs allowed through the vault firewall."
  type        = list(string)
  default     = []
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.vaultcore.azure.net."
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for the vault private endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for Key Vault resources."
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID."
  type        = string
}
