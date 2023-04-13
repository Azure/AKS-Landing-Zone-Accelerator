####################################
# These resources will create an addtional subnet for user connectivity
# and a Linux Server to use with the Bastion Service.
####################################

# Dev Subnet
# (Additional subnet for Developer Jumpbox)
resource "azurerm_subnet" "dev" {
  name                                      = "devSubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.0.4.0/24"]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_network_security_group" "dev-nsg" {
  name                = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.dev.name}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.dev.id
  network_security_group_id = azurerm_network_security_group.dev-nsg.id
}

# Linux Server VM

module "create_linuxsserver" {
  source = "./modules/compute-linux"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  vnet_subnet_id      = azurerm_subnet.dev.id

  server_name    = "server-dev-linux"
  admin_username = var.admin_username
  admin_password = var.admin_password
}

#######################
# SENSITIVE VARIABLES #
#######################

variable "admin_password" {
  default = "change me"
}

variable "admin_username" {
  default = "sysadmin"
}