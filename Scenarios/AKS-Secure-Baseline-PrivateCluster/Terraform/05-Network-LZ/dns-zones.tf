
# # Deploy DNS Private Zone for ACR

resource "azurerm_private_dns_zone" "acr-dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.spoke-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_acr" {
  name                  = replace(module.CAFResourceNames.names.azurerm_private_dns_zone_virtual_network_link, "pnetlk", "${var.lz_prefix}acrspnetlk")
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_acr" {
  name                  = replace(module.CAFResourceNames.names.azurerm_private_dns_zone_virtual_network_link, "pnetlk", "hubacrspnetlk")
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr-dns.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

# # Deploy DNS Private Zone for KV

resource "azurerm_private_dns_zone" "kv-dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.spoke-rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_kv" {
  name                  = replace(module.CAFResourceNames.names.azurerm_private_dns_zone_virtual_network_link, "pnetlk", "${var.lz_prefix}kvspnetlk")
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub_kv" {
  name                  = replace(module.CAFResourceNames.names.azurerm_private_dns_zone_virtual_network_link, "pnetlk", "hubkvspnetlk")
  resource_group_name   = azurerm_resource_group.spoke-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
  virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
}

#############
## OUTPUTS ##
#############
# These outputs are used by later deployments
output "acr_private_zone_id" {
  value = azurerm_private_dns_zone.acr-dns.id
}

output "acr_private_zone_name" {
  value = azurerm_private_dns_zone.acr-dns.name
}

output "kv_private_zone_id" {
  value = azurerm_private_dns_zone.kv-dns.id
}

output "kv_private_zone_name" {
  value = azurerm_private_dns_zone.kv-dns.name
}
