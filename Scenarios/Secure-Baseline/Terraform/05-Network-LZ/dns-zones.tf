
# # Deploy DNS Private Zone for ACR

resource "azurerm_private_dns_zone" "acr-dns" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.net-rg.name

}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_acr" {
  name                  = "lz_to_acrs"
  resource_group_name   = azurerm_resource_group.net-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.acr-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

output "acr_private_zone_id" {
  value = azurerm_private_dns_zone.acr-dns.id
}

output "acr_private_zone_name" {
  value = azurerm_private_dns_zone.acr-dns.name
}

# # Deploy DNS Private Zone for KV

resource "azurerm_private_dns_zone" "kv-dns" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.net-rg.name

}

resource "azurerm_private_dns_zone_virtual_network_link" "lz_kv" {
  name                  = "lz_to_kvs"
  resource_group_name   = azurerm_resource_group.net-rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv-dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

output "kv_private_zone_id" {
  value = azurerm_private_dns_zone.kv-dns.id
}

output "kv_private_zone_name" {
  value = azurerm_private_dns_zone.kv-dns.name
}

# # Deploy DNS Private Zone for AKS

# resource "azurerm_private_dns_zone" "aks-dns" {
#   name                = "privatelink.eastus.azmk8s.io"
#   resource_group_name = azurerm_resource_group.rg.name

# }

# resource "azurerm_private_dns_zone_virtual_network_link" "hub_aks" {
#   name                  = "hub_to_aks"
#   resource_group_name = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.aks-dns.name
#   virtual_network_id    = module.create_vnet.vnet_id
# }

# output "aks_private_zone_id" {
#   value = azurerm_private_dns_zone.aks-dns.id
# }

# output "aks_private_zone_name" { 
#   value = azurerm_private_dns_zone.aks-dns.name
# }
