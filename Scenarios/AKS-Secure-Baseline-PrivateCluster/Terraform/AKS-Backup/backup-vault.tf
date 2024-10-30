resource "azurerm_data_protection_backup_vault" "backup-vault" {
  name                = "backup-vault"
  resource_group_name = azurerm_resource_group.rg-backup.name
  location            = azurerm_resource_group.rg-backup.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant" # `GeoRedundant`
  # cross_region_restore_enabled = "false" # can only be specified when `redundancy` is specified for `GeoRedundant`
  soft_delete                = "Off"
  retention_duration_in_days = 14

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "vault_msi_read_on_cluster" {
  scope                = var.aksClusterId
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_read_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_snapshot_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Disk Snapshot Contributor"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_data_operator_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Data Operator for Managed Disks"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}

resource "azurerm_role_assignment" "vault_msi_data_contributor_on_storage" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}
