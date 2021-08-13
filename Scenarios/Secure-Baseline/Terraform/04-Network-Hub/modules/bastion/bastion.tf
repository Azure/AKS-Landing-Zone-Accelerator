resource "azurerm_subnet" "bastionhost" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes       = [var.subnet_cidr]
}

resource "azurerm_public_ip" "bastionhost" {
  name                = "${var.virtual_network_name}-bastion-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastionhost" {
  name                = "${var.virtual_network_name}-bastion"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                 = "configuration"
    subnet_id = azurerm_subnet.bastionhost.id
    public_ip_address_id = azurerm_public_ip.bastionhost.id
  }
}