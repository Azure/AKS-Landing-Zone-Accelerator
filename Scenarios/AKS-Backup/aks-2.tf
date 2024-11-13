resource "azurerm_kubernetes_cluster" "aks-2" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.rg-2.location
  resource_group_name = azurerm_resource_group.rg-2.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.30.5"

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    # subnet_id           = azurerm_subnet.snet-aks-2.id
  }

  default_node_pool {
    name                        = "systempool"
    temporary_name_for_rotation = "syspool"
    node_count                  = 3
    vm_size                     = "standard_b2als_v2"
    zones                       = [1, 2, 3]
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool.0.upgrade_settings
    ]
  }
}



resource "azurerm_role_assignment" "cluster_2_msi_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks-2.identity.0.principal_id
}

resource "azurerm_kubernetes_cluster_extension" "extension-2" {
  name              = "backup-extension"
  cluster_id        = azurerm_kubernetes_cluster.aks-2.id
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

resource "azurerm_role_assignment" "extension_2_storage_account_contributor" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_kubernetes_cluster_extension.extension-2.aks_assigned_identity[0].principal_id
}

resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "aks_2_trusted_access" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-2.id
  name                  = "trusted-access"
  roles                 = ["Microsoft.DataProtection/backupVaults/backup-operator"]
  source_resource_id    = azurerm_data_protection_backup_vault.backup-vault.id
}

resource "azurerm_role_assignment" "vault_msi_read_on_cluster_2" {
  scope                = azurerm_kubernetes_cluster.aks-2.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.backup-vault.identity[0].principal_id
}