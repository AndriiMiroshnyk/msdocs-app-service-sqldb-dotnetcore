data "azurerm_client_config" "current" {}

module "resource_group" {
  source = "./modules/resource-group"

  name     = var.resource_group_name
  location = var.location
}

module "networking" {
  source = "./modules/networking"

  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  virtual_network_name         = "vnet-${var.web_app_name}"
  address_space                = var.vnet_address_space
  integration_subnet_cidr      = var.integration_subnet_cidr
  private_endpoint_subnet_cidr = var.private_endpoint_subnet_cidr
}

module "sql" {
  source = "./modules/sql"

  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  server_name                = var.sql_server_name
  database_name              = var.sql_database_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  entra_admin_login_name     = var.sql_entra_admin_login_name
  entra_admin_object_id      = var.sql_entra_admin_object_id
  database_sku_name          = var.sql_database_sku_name
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.private_dns_zone_ids["sql"]
}

module "key_vault" {
  source = "./modules/key-vault"

  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  name                       = var.key_vault_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  private_dns_zone_id        = module.networking.private_dns_zone_ids["key_vault"]
  operator_ipv4_cidrs        = var.operator_ipv4_cidrs
  certificate_operator_object_id = try(var.custom_domain.tls_certificate, null) != null ? (
    coalesce(var.certificate_operator_object_id, data.azurerm_client_config.current.object_id)
  ) : var.certificate_operator_object_id
}

module "app_service" {
  source = "./modules/app-service"

  resource_group_name       = module.resource_group.name
  location                  = module.resource_group.location
  web_app_name              = var.web_app_name
  service_plan_name         = var.service_plan_name
  application_insights_name = var.application_insights_name
  action_group_name         = var.action_group_name
  sku_name                  = var.service_plan_sku_name
  dotnet_version            = var.dotnet_version
  staging_slot_name         = var.staging_slot_name
  log_retention_days        = var.log_retention_days
  integration_subnet_id     = module.networking.integration_subnet_id
  sql_server_fqdn           = module.sql.server_fqdn
  sql_database_name         = module.sql.database_name
}

module "dns_traffic" {
  source = "./modules/dns-traffic"

  resource_group_name           = module.resource_group.name
  profile_name                  = var.traffic_manager_name
  endpoint_name                 = var.traffic_manager_endpoint_name
  web_app_id                    = module.app_service.web_app_id
  custom_domain_verification_id = module.app_service.custom_domain_verification_id
  custom_domain                 = var.custom_domain
}

module "certificate" {
  source = "./modules/certificate"
  count  = try(var.custom_domain.enable_binding, false) ? 1 : 0

  resource_group_name  = module.resource_group.name
  location             = module.resource_group.location
  web_app_name         = module.app_service.web_app_name
  service_plan_id      = module.app_service.service_plan_id
  certificate_name     = var.certificate_name
  certificate_password = var.certificate_password
  hostname             = module.dns_traffic.custom_hostname
  key_vault_id         = module.key_vault.id
  tls_certificate      = var.custom_domain.tls_certificate

  # Create DNS records and the certificate operator's role before certificate resources.
  depends_on = [module.dns_traffic, module.key_vault]
}
