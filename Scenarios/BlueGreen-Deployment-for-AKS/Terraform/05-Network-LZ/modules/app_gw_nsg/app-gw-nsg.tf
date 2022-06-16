resource "azurerm_network_security_group" "appgw-nsg" {
  name                = var.nsg_name
  resource_group_name                            = var.resource_group_name
  location            = var.location
}

output "appgw_nsg_id" {
  value = azurerm_network_security_group.appgw-nsg.id
}

resource "azurerm_network_security_rule" "inboundhttps" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
  name                        = "Allow443InBound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "VirtualNetwork"

}

resource "azurerm_network_security_rule" "controlplane" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
  name                        = "AllowControlPlane"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "healthprobes" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
  name                        = "AllowHealthProbes"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_address_prefix  = "VirtualNetwork"

}

resource "azurerm_network_security_rule" "DenyAllInBound" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.appgw-nsg.name
  name                        = "DenyAllInBound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"

}

# resource "azurerm_network_security_rule" "AllowAllOutBound" {
#   name                        = "AllowAllOutBound"
#   priority                    = 1000
#   direction                   = "Outbound"
#   access                      = "Allow"
#   protocol                    = "Any"
#   source_port_range           = "*"
#   destination_port_range      = "*"
#   source_address_prefix       = "*"
#   destination_address_prefix  = "*"
#   resource_group_name         = var.resource_group_name
#   network_security_group_name = var.network_security_group_name
# }


variable "location" {

}

variable "resource_group_name" {

}

variable "nsg_name" {}

