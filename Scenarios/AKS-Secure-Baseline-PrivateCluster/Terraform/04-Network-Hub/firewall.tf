
# Azure Firewall 
# --------------
# Firewall Rules created via Module

resource "azurerm_firewall" "firewall" {
  name                = "${azurerm_virtual_network.vnet.name}-firewall"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewall_policy_id  = module.firewall_rules_aks.fw_policy_id

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_public_ip" "firewall" {
  name                 = "${azurerm_virtual_network.vnet.name}-firewall-pip"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  allocation_method    = "Static"
  sku                  = "Standard"
}

module "firewall_rules_aks" {
  source = "./modules/aks-fw-rules"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

}
