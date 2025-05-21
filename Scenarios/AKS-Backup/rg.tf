resource "azurerm_resource_group" "rg-backup" {
  name     = "rg-aks-backup"
  location = var.location1
}

resource "azurerm_resource_group" "rg-2" {
  name     = "rg-aks-2"
  location = var.location2
}