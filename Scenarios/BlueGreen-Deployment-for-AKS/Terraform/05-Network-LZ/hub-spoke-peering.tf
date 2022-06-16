
# Peering Landing Zone (Spoke) Network to Connectivity (Hub) Network
## This assumes that the SP being used for this deployment has Network Contributor rights
## on the subscription(s) where the VNETs reside.  
## If multiple subscriptions are used, provider aliases will be required. 

# Spoke to Hub
resource "azurerm_virtual_network_peering" "direction1" {
  name                         = "${azurerm_virtual_network.vnet.name}-to-${data.terraform_remote_state.existing-hub.outputs.hub_vnet_name}"
  resource_group_name          = azurerm_resource_group.net-rg.name
  virtual_network_name         = azurerm_virtual_network.vnet.name
  remote_virtual_network_id    = data.terraform_remote_state.existing-hub.outputs.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

}

# Hub to Spoke
resource "azurerm_virtual_network_peering" "direction2" {
  name                         = "${data.terraform_remote_state.existing-hub.outputs.hub_vnet_name}-to-${azurerm_virtual_network.vnet.name}"
  resource_group_name          = data.terraform_remote_state.existing-hub.outputs.hub_rg_name
  virtual_network_name         = data.terraform_remote_state.existing-hub.outputs.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false

}