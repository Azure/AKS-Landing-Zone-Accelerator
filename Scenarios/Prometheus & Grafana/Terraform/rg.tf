resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-monitoring-${var.prefix}"
  location = var.location
}