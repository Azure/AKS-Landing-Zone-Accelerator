resource "azurerm_storage_account" "storage" {
  name                             = "storage19753"
  resource_group_name              = azurerm_resource_group.rg-backup.name
  location                         = azurerm_resource_group.rg-backup.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  cross_tenant_replication_enabled = true
}

resource "azurerm_storage_container" "container" {
  name                  = "backup-container"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
