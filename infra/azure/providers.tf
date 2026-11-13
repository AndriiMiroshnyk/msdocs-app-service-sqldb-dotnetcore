provider "azurerm" {
  subscription_id = var.subscription_id

  # Required resource providers must be registered before deployment.
  resource_provider_registrations = "none"

  features {
    key_vault {
      # Disable automatic recovery and purge of soft-deleted vaults and certificates.
      purge_soft_delete_on_destroy               = false
      recover_soft_deleted_key_vaults            = false
      purge_soft_deleted_certificates_on_destroy = false
      recover_soft_deleted_certificates          = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
