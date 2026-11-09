resource "azurerm_app_service_custom_hostname_binding" "this" {
  hostname            = var.hostname
  app_service_name    = var.web_app_name
  resource_group_name = var.resource_group_name

  # The separate TLS binding resource owns these properties.
  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_role_assignment" "app_service_certificate" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = var.tls_certificate.app_service_principal_object_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_key_vault_certificate" "this" {
  name         = var.tls_certificate.key_vault_certificate_name
  key_vault_id = var.key_vault_id

  certificate {
    contents = filebase64(pathexpand(var.tls_certificate.pfx_file_path))
    password = var.certificate_password
  }
}

resource "azurerm_app_service_certificate" "this" {
  name                = coalesce(var.certificate_name, "${var.web_app_name}-custom-tls")
  resource_group_name = var.resource_group_name
  location            = var.location
  app_service_plan_id = var.service_plan_id
  key_vault_id        = var.key_vault_id
  key_vault_secret_id = azurerm_key_vault_certificate.this.secret_id

  depends_on = [azurerm_role_assignment.app_service_certificate]
}

resource "azurerm_app_service_certificate_binding" "this" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.this.id
  certificate_id      = azurerm_app_service_certificate.this.id
  ssl_state           = "SniEnabled"
}
