resource "azurerm_traffic_manager_profile" "this" {
  name                   = var.profile_name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = var.profile_name
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTPS"
    port                         = 443
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "this" {
  name               = var.endpoint_name
  profile_id         = azurerm_traffic_manager_profile.this.id
  target_resource_id = var.web_app_id
  enabled            = true
}

resource "azurerm_dns_zone" "this" {
  count               = var.custom_domain == null ? 0 : 1
  name                = var.custom_domain.zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_cname_record" "application" {
  count               = var.custom_domain == null ? 0 : 1
  name                = var.custom_domain.record_name
  zone_name           = azurerm_dns_zone.this[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_traffic_manager_profile.this.id
}

resource "azurerm_dns_txt_record" "verification" {
  count               = var.custom_domain == null ? 0 : 1
  name                = "asuid.${var.custom_domain.record_name}"
  zone_name           = azurerm_dns_zone.this[0].name
  resource_group_name = var.resource_group_name
  ttl                 = 3600

  record {
    value = var.custom_domain_verification_id
  }
}
