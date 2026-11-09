locals {
  private_dns_zones = {
    sql       = "privatelink.database.windows.net"
    key_vault = "privatelink.vaultcore.azure.net"
  }
}
