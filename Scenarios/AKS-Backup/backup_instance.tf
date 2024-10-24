resource "azurerm_data_protection_backup_instance_kubernetes_cluster" "backup_instance_aks" {
  name                         = "backup-instance-aks"
  location                     = azurerm_resource_group.rg-backup.location
  vault_id                     = azurerm_data_protection_backup_vault.backup-vault.id
  kubernetes_cluster_id        = azurerm_kubernetes_cluster.aks-1.id
  snapshot_resource_group_name = azurerm_resource_group.rg-backup.name
  backup_policy_id             = azurerm_data_protection_backup_policy_kubernetes_cluster.backup_policy_aks.id

  backup_datasource_parameters {
    # excluded_namespaces              = ["ns1"]
    # excluded_resource_types          = ["exvolumesnapshotcontents.snapshot.storage.k8s.io"]
    cluster_scoped_resources_enabled = true
    # included_namespaces              = ["*"] # ["test-included-namespaces"]
    # included_resource_types          = ["*"] # ["involumesnapshotcontents.snapshot.storage.k8s.io"]
    # label_selectors                  = ["*"] # ["kubernetes.io/metadata.name:test"]
    volume_snapshot_enabled = true
  }

  depends_on = [
    azurerm_role_assignment.extension_1_storage_account_contributor,
    azurerm_role_assignment.vault_msi_read_on_cluster,
    azurerm_role_assignment.vault_msi_read_on_snap_rg,
    azurerm_role_assignment.cluster_msi_contributor_on_snap_rg,
    azurerm_role_assignment.vault_msi_snapshot_contributor_on_snap_rg,
    azurerm_role_assignment.vault_msi_data_operator_on_snap_rg,
    azurerm_role_assignment.vault_msi_data_contributor_on_storage,
  ]
}
