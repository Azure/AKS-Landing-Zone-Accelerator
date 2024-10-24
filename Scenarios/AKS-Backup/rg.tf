resource "azurerm_resource_group" "rg-1" {
  name     = "rg-aks-1-${var.prefix}"
  location = var.location1
}

resource "azurerm_resource_group" "rg-backup" {
  name     = "rg-aks-backup-${var.prefix}"
  location = var.location1
}

resource "azurerm_resource_group" "rg-2" {
  name     = "rg-aks-2-${var.prefix}"
  location = var.location2
}