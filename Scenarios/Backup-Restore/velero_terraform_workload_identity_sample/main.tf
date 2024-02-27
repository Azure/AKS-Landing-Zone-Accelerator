# following this guide: https://learn.microsoft.com/en-us/azure/aks/hybrid/backup-workload-cluster#install-velero-with-azure-blob-storage
# but using guidance from here for workload identity: https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure

# basically, we need a storage account (files + blob) in which velero can write the backup.
# this storage account should be connected via private endpoint to the AKS cluster
# for least privilege, we create a custom role
# for the identity, we use workload federation
resource "azurerm_resource_group" "velero" {
  name     = "velero-backup"
  location = "westeurope"
}

resource "azurerm_storage_account" "velero" {
  name                            = "velerodemobackupacc"
  resource_group_name             = azurerm_resource_group.velero.name
  location                        = azurerm_resource_group.velero.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  network_rules {
    default_action = "Deny"
    bypass         = ["Logging", "Metrics"]
  }

  enable_https_traffic_only = true
}

resource "azurerm_private_endpoint" "velero_file" {
  name                = "velero-file"
  location            = azurerm_resource_group.velero.location
  resource_group_name = azurerm_resource_group.velero.name
  subnet_id           = azurerm_subnet.vm.id
  private_service_connection {
    name                           = "velero-file"
    private_connection_resource_id = azurerm_storage_account.velero.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
  lifecycle {
    ignore_changes = [private_dns_zone_group]  # when using azure enterprise scale landing zone, the DNS entries are created automatically via policy
  }
}

resource "azurerm_private_endpoint" "velero_blob" {
  name                = "velero-blob"
  location            = azurerm_resource_group.velero.location
  resource_group_name = azurerm_resource_group.velero.name
  subnet_id           = azurerm_subnet.vm.id
  private_service_connection {
    name                           = "velero-blob"
    private_connection_resource_id = azurerm_storage_account.velero.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  lifecycle {
    ignore_changes = [private_dns_zone_group] # when using azure enterprise scale landing zone, the DNS entries are created automatically via policy
  }
}

resource "azurerm_storage_container" "velero" {
  name                  = "velero"
  storage_account_name  = azurerm_storage_account.velero.name
  container_access_type = "private"
}

resource "azurerm_role_definition" "velero" {
  name              = "[slcorp] Velero Backup Operator"
  description       = "Velero related permissions to perform backups, restores and deletions"
  assignable_scopes = ["/subscriptions/${var.subscription_id}"]
  scope             = "/subscriptions//${var.subscription_id}"
  permissions {
    actions = [
      "Microsoft.Compute/disks/read",
      "Microsoft.Compute/disks/write",
      "Microsoft.Compute/disks/endGetAccess/action",
      "Microsoft.Compute/disks/beginGetAccess/action",
      "Microsoft.Compute/snapshots/read",
      "Microsoft.Compute/snapshots/write",
      "Microsoft.Compute/snapshots/delete",
      "Microsoft.Storage/storageAccounts/listkeys/action",
      "Microsoft.Storage/storageAccounts/regeneratekey/action"
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action"
    ]
  }
}



resource "azurerm_user_assigned_identity" "velero" {
  name                = "aks-velero-workload-identity"
  resource_group_name = azurerm_resource_group.velero.name
  location            = azurerm_resource_group.velero.location
}

resource "azurerm_federated_identity_credential" "velero" {
  resource_group_name = azurerm_resource_group.velero.name
  parent_id           = azurerm_user_assigned_identity.velero.id
  name                = "demo_workload"
  issuer              = azurerm_kubernetes_cluster.cluster.oidc_issuer_url
  subject             = "system:serviceaccount:velero:aks-velero-workload-identity"
  audience            = ["api://AzureADTokenExchange"]
}


resource "azurerm_role_assignment" "velero" {
  scope                = azurerm_resource_group.velero.id
  role_definition_name = azurerm_role_definition.velero.name
  principal_id         = azurerm_user_assigned_identity.velero.principal_id
}

