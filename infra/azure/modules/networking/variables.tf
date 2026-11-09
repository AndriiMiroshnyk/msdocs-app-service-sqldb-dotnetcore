variable "address_space" {
  description = "Virtual network IPv4 address space."
  type        = string
  default     = "10.0.0.0/16"
}

variable "integration_subnet_cidr" {
  description = "Subnet delegated to App Service."
  type        = string
  default     = "10.0.1.0/24"
}

variable "integration_subnet_name" {
  description = "Name of the App Service integration subnet."
  type        = string
  default     = "app-service-integration"
}

variable "location" {
  description = "Azure region for the virtual network."
  type        = string
}

variable "private_endpoint_subnet_cidr" {
  description = "Subnet for private endpoints."
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_endpoint_subnet_name" {
  description = "Name of the private endpoint subnet."
  type        = string
  default     = "private-endpoints"
}

variable "resource_group_name" {
  description = "Resource group for the virtual network and private DNS."
  type        = string
}

variable "virtual_network_name" {
  description = "Virtual network name."
  type        = string
}
