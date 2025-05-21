resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "aks_1_trusted_access" {
  kubernetes_cluster_id = data.azurerm_kubernetes_cluster.aks-1.id # var.aksClusterId
  name                  = "trusted-access"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = azurerm_data_protection_backup_vault.backup-vault.id
}