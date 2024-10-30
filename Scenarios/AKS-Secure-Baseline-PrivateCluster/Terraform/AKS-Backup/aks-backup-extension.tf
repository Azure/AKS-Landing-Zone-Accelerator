resource "azurerm_kubernetes_cluster_extension" "extension-1" {
  name              = "backup-extension"
  cluster_id        = var.aksClusterId
  extension_type    = "Microsoft.DataProtection.Kubernetes"
  release_train     = "stable"
  release_namespace = "dataprotection-microsoft"
  configuration_settings = {
    "configuration.backupStorageLocation.bucket"                = azurerm_storage_container.container.name
    "configuration.backupStorageLocation.config.storageAccount" = azurerm_storage_account.storage.name
    "configuration.backupStorageLocation.config.resourceGroup"  = azurerm_storage_account.storage.resource_group_name
    "configuration.backupStorageLocation.config.subscriptionId" = data.azurerm_client_config.current.subscription_id
    "credentials.tenantId"                                      = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_role_assignment" "extension_1_storage_account_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.extension-1.aks_assigned_identity[0].principal_id
}

data "azurerm_client_config" "current" {}