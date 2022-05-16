locals {
  credentials = <<EOF
AZURE_SUBSCRIPTION_ID = ${try(data.azurerm_subscription.current.subscription_id, "")}
AZURE_RESOURCE_GROUP = ${var.aks_nodes_resource_group_name}
AZURE_CLOUD_NAME = AzurePublicCloud
AZURE_TENANT_ID = ${var.velero_sp_tenantID}
AZURE_CLIENT_ID = ${var.velero_sp_clientID}
AZURE_CLIENT_SECRET = ${var.velero_sp_clientSecret}
EOF

  velero_default_values = {
    "restoreOnlyMode"                                           = try(var.velero_restore_mode_only, "false")
    "defaultVolumesToRestic"                                           = try(var.velero_default_volumes_to_restic, "true")
    "configuration.backupStorageLocation.bucket"                = try(var.backups_stracc_container_name, "")
    "configuration.backupStorageLocation.config.resourceGroup"  = try(var.backups_rg_name, "")
    "configuration.backupStorageLocation.config.storageAccount" = try(var.backups_stracc_name, "")
    "configuration.backupStorageLocation.name"                  = "default"
    "configuration.provider"                                    = "azure"
    "configuration.volumeSnapshotLocation.config.resourceGroup" = try(var.backups_rg_name, "")
    "configuration.volumeSnapshotLocation.name"                 = "default"
    "credentials.existingSecret"                                = try(kubernetes_secret.velero.metadata[0].name, "")
    "credentials.useSecret"                                     = "true"
    "deployRestic"                                              = "true"
    "env.AZURE_CREDENTIALS_FILE"                                = "/credentials"
    "metrics.enabled"                                           = "true"
    "rbac.create"                                               = "true"
    "schedules.daily.schedule"                                  = "0 23 * * *"
    "schedules.daily.template.includedNamespaces"               = "{*}"
    "schedules.daily.template.snapshotVolumes"                  = "true"
    "schedules.daily.template.ttl"                              = "240h"
    "serviceAccount.server.create"                              = "true"
    "snapshotsEnabled"                                          = "false"
    "initContainers[0].name"                                    = "velero-plugin-for-azure"
    "initContainers[0].image"                                   = "velero/velero-plugin-for-microsoft-azure:v1.4.1"
    "initContainers[0].volumeMounts[0].mountPath"               = "/target"
    "initContainers[0].volumeMounts[0].name"                    = "plugins"
    #"initContainers[1].name"                                    = "velero-plugin-for-csi"
    #"initContainers[1].image"                                   = "velero/velero-plugin-for-csi:v0.1.1"
    #"initContainers[1].volumeMounts[0].mountPath"               = "/target"
    #"initContainers[1].volumeMounts[0].name"                    = "plugins"
    #"features"                                                  = "EnableCSI"
    "image.repository"                                          = "velero/velero"
    "image.tag"                                                 = "v1.8.1"
    "image.pullPolicy"                                          = "IfNotPresent"
  }

  velero_credentials = local.credentials

  velero_values      = merge(local.velero_default_values, var.velero_values)

}
