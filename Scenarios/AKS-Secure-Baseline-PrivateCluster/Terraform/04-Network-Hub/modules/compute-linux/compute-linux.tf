resource "azurerm_linux_virtual_machine" "compute" {

  name                            = var.server_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = var.disable_password_authentication //Set to true if using SSH key


  tags = var.tags

  network_interface_ids = [
    azurerm_network_interface.compute.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  admin_ssh_key {
    username   = var.ssh_key_settings.username
    public_key = var.ssh_key_settings.public_key
  }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version

  }

  boot_diagnostics {
    storage_account_uri = null
  }
}

resource "azurerm_public_ip" "pip" {
    name                         = "dev-pip"
    location                     = var.location
    resource_group_name          = var.resource_group_name
    allocation_method            = var.allocation_method
    sku                          = "Standard"
}


resource "azurerm_network_interface" "compute" {

  name                          = "${var.server_name}-nic"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  enable_accelerated_networking = var.enable_accelerated_networking

  tags = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vnet_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}


variable "admin_username" {
  default = "sysadmin"
}

variable "admin_password" {
  default = "changeme"
}

variable "server_name" {

}
variable "resource_group_name" {

}
variable "location" {

}
variable "vnet_subnet_id" {

}
variable "os_publisher" {
  default = "Canonical"
}
variable "os_offer" {
  default = "UbuntuServer"
}
variable "os_sku" {
  default = "18.04-LTS"
}
variable "os_version" {
  default = "latest"
}
variable "disable_password_authentication" {
  default = true #leave as true if using ssh key, if using a password make the value false
}
variable "enable_accelerated_networking" {
  default = "false"
}
variable "storage_account_type" {
  default = "Standard_LRS"
}
variable "vm_size" {
  default = "Standard_D2s_v3"
}
variable "tags" {
  type = map(string)

  default = {
    application = "compute"
  }
}
variable "ssh_key_settings" {
  type    = map(string)
  default =  null
}

variable "allocation_method" {
  default = "Static"
}