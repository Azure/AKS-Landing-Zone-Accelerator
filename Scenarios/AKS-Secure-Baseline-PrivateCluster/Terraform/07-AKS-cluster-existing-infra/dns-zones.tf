# Deploy DNS Private Zone for AKS
resource "azurerm_private_dns_zone" "aks-dns" {
  name                = var.private_dns_zone_name
  resource_group_name = var.existing_spoke_vnet_rg_name // lives in the spoke rg
}

# Needed for Jumpbox to resolve cluster URL using a private endpoint and private dns zone
resource "azurerm_private_dns_zone_virtual_network_link" "hub_aks" {
  name                  = "hub_to_aks"
  resource_group_name   = var.existing_spoke_vnet_rg_name // lives in the spoke rg
  private_dns_zone_name = azurerm_private_dns_zone.aks-dns.name
  virtual_network_id    = var.existing_hub_vnet_id
}

output "aks_private_zone_id" {
  value = azurerm_private_dns_zone.aks-dns.id
}
output "aks_private_zone_name" {
  value = azurerm_private_dns_zone.aks-dns.name
}