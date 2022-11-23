
# Velero configuration for Microsoft Azure

## Overview

Velero is a plugin based tool. You can use the following plugins to run Velero on Microsoft Azure:

<a href="https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure" target="_blank">velero-plugin-for-microsoft-azure</a>, which provides:

- **An object store plugin** for persisting and retrieving backups on Azure Blob Storage. Content of backup is metadata (log files, warning/error files, restore logs) + cluster configuration.

- **A volume snapshotter plugin** for creating snapshots from volumes (during a backup) and volumes from snapshots (during a restore) on Azure Managed Disks.
  - It supports Azure Disk provisioned by Kubernetes driver `kubernetes.io/azure-disk`
  - Since v1.4.0 the snapshotter plugin can handle the volumes provisioned by CSI driver `disk.csi.azure.com`
  - Limitation: IT DOES NOT support Azure File

 <a href="https://github.com/vmware-tanzu/velero-plugin-for-csi" target="_blank">velero-plugin-for-csi</a>
  - **A volume snapshotter plugin** for CSI backed PVCs using the CSI beta snapshot APIs for Kubernetes. 
  - See [how Velero supports CSI Snapshot API](https://velero.io/docs/v1.8/csi/)
  - It supports [Azure Disks](https://learn.microsoft.com/azure/aks/azure-disk-csi) `disk.csi.azure.com`
  - Volume snapshots are configured using a VolumeSnapshotClass:
        - <a href="https://github.com/kubernetes-sigs/azuredisk-csi-driver/blob/master/deploy/example/snapshot/storageclass-azuredisk-snapshot.yaml" target="_blank">Azure Disk VolumeSnapshotClass</a>
  - Limitation: 
      - Currently CSI snapshots in a different region from the primary AKS cluster, is not supported -> Coming Soon !
      - Azure File is not yet fully supported: https://github.com/kubernetes-sigs/azurefile-csi-driver/tree/master/deploy/example/snapshot

  <a href="https://velero.io/docs/v1.8/restic/" target="_blank">restic</a>
  - **A filesystem backup plugin** (also called block to block copy, which does not rely on snapshots) --> Velero’s Restic integration backs up data from volumes by accessing the node’s filesystem, on which the pod is running.
  - It supports both Azure Disk and Azure File, with both `kubernetes.io` and CSI drivers.
  - If you are using Azure Files, you need to add nouser_xattr to your storage class’s mountOptions. See [Azure File application sample](../applications_samples/azurefile_LRS.yaml)
  - Use [Backup Hooks](https://velero.io/docs/v1.8/backup-hooks/) for freezing a file system, to ensure that all pending disk I/O operations have completed prior to taking a snapshot, 
  - Limitations: https://velero.io/docs/v1.8/restic/#limitations


*Note*: Velero does not officially [support for Windows containers][10]. If your cluster has both Windows and Linux agent pool, add a node selector to the `velero` deployment to run Velero only on the Linux nodes. This can be done using the below command.
    ```bash
    kubectl patch deploy velero --namespace velero --type merge --patch '{ \"spec\": { \"template\": { \"spec\": { \"nodeSelector\": { \"beta.kubernetes.io/os\": \"linux\"} } } } }'
    
    
## Which plugin to use ?

Velero’s backups are split into 2 pieces :
- the metadata + cluster configuration stored in object storage, 
- and snapshots/backups of the persistent volumes




**For Backup & Restore of metadata + cluster configuration:**

  -  Velero has a concept of *BackupStorageLocation* : defined as a container (in an Azure Storage Account), in which all Velero data is stored. (You can define multiple BackupStorageLocations for different backup destinations)

  -  On Azure, you would use `velero-plugin-for-microsoft-azure` for storing Velero data, **in addition** to a plugin/configuration for persisent volumes backups.

   - See <a href="https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/main/backupstoragelocation.md" target="_blank">addiotnal parameters</a> for the `--backup-location-config` flag.





**For Backup & Restore of persistent volumes:**

   -    If you are using StorageClasses with provisioners `kubernetes.io/azure-disk` and `kubernetes.io/azure-file`:
          - It might be simpler to use filesystem backup with Restic as it works with Azure File & Azure Disk.
       
   -    If you are using StorageClasses with provisioner `file.csi.azure.com`:
          - Use filesystem backup with Restic (due to current limitation of Azure File CSI Driver snapshots).
       
   -    If you are using StorageClasses with provisioner `disk.csi.azure.com`:
          - use CSI drivers for Azure Disk with **ZRS sku** for availbility zone support.
          - You can use CSI Snapshots to restore to a cluster in the same Region.
          - Regional volume snapshot with CSI Driver is coming soon ! --> to Restore to a cluster in a secondary region, use Restic for now

   -    Note on [Azure Disk Availability Zone support](https://learn.microsoft.com/azure/aks/availability-zones#azure-disk-availability-zone-support)
           - Volumes that use Azure managed LRS disks are not zone-redundant resources, those volumes cannot be attached across zones and must be co-located in the same zone as a given node hosting the target pod   
           - Kubernetes is aware of Azure availability zones since version 1.12. You can deploy a PersistentVolumeClaim object referencing an Azure Managed Disk in a multi-zone AKS cluster and Kubernetes will take care of scheduling any pod that claims this PVC in the correct availability zone.
           - See How to use Availability Zones in your StorageClasses: https://kubernetes-sigs.github.io/cloud-provider-azure/topics/availability-zones/
           - for backing up LRS Disks, you can use filesystem backup with Restic, which is not impacted by availability zones



 ## Compatibility

  Below is a listing of plugin versions and respective Velero versions that are compatible.

  | velero-plugin-for-microsoft-azure| Velero (with restic)  |   velero-plugin-for-csi | Kubernetes    |
  |----------------------------------|---------|-------------------------|---------------|           
  | v1.4.x                           | v1.8.x  |        N/A              |  1.16-latest  |
  | v1.3.x                           | v1.7.x  |       v0.2.0            |  1.12-latest  |
  | v1.2.x                           | v1.6.x  |       v0.1.2            |  1.12-1.21    |
  | v1.1.x                           | v1.5.x  |       v0.1.2            |  1.12-1.21    |
  | v1.1.x                           | v1.4.x  |       v0.1.1            |  1.12-1.21    |

  - https://github.com/vmware-tanzu/velero#velero-compatibility-matrix
  - https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure#compatibility
  - https://github.com/vmware-tanzu/velero-plugin-for-csi#compatibility

  - This sample code installs velero using Helm Chart: to see available versions for Velero Chart, use the command     
  ```bash
   helm search repo  vmware-tanzu/velero --versions
  ```

## Using the module

The modules provides a solution to automate the steps described in the article https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure

```hcl
#Deploy Velero on primary cluster AKS1
module "velero" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  source = "./modules/velero"

  providers = {
    kubernetes = kubernetes.aks-module
    helm       = helm.aks-module
  }

  backups_region       = var.backups_region
  backups_rg_name           = var.backups_rg_name
  backups_stracc_name           = var.backups_stracc_name
  backups_stracc_container_name           = var.backups_stracc_container_name
  aks_nodes_resource_group_name = data.azurerm_kubernetes_cluster.aks.node_resource_group

  velero_namespace        = var.velero_namespace
  velero_chart_repository = var.velero_chart_repository
  velero_chart_version    = var.velero_chart_version
  velero_values           = var.velero_values


  velero_sp_tenantID = data.azurerm_client_config.current.tenant_id 
  velero_sp_clientID = data.azuread_service_principal.velero_sp.application_id 
  velero_sp_clientSecret = azuread_service_principal_password.velero_sp_password.value 
}

```

 ## Using the sample code for your own clusters

 <a href="./providers.tf" target="_blank">providers.tf</a>:
  - Defines the Terraform providers used to automate the deployment and configuration of resources
    - azurerm
    - kubernetes
    - helm


 <a href="./01-aks1.tf" target="_blank">01-aks1.tf</a>:
  - Creates a Resource Group in Primary Region
  - Creates an AKS Cluster (used as primary)


 <a href="./02-aks1-dr.tf" target="_blank">02-aks-dr.tf</a>:
  - Creates a Resource Group in Secondary Region
  - Creates an AKS Cluster (used as secondary, to restore backup)

 <a href="./03-backup-location.tf" target="_blank">03-backup-location.tf</a>:
  - Creates a Resource Group in Secondary Region, for hosting storage location (to store backups and velero configuration)
  - Creates a storage account 
  - Creates a storage container, used by velero (Optionnaly, you could create a secondary container, to backup your backup cluster)


 <a href="./main.tf" target="_blank">maint.tf</a>:
  - References the created ressources: primary and secondary RGs + AKS clusters + storage account (you should be able to reuse it for your existing resources)
  - Creates RBACs for Velero Service Principal. See this <a href="https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure#set-permissions-for-velero" target="_blank">article</a> for defining minium permissions.  
  - **Installs Velero on the AKS Clusters using the provided module** (enable Restic for filesystem backup)


## Customizing the module


The module installs velero using helm chart. You can customize velero configuration by editing the file <a href="./modules/velero/locals-velero.tf" target="_blank">locals-velero.tf</a>:

You can see the supported Velero values: https://github.com/vmware-tanzu/helm-charts/blob/main/charts/velero/values.yaml
 
 

```hcl
velero_default_values = {
    "restoreOnlyMode"                                           = try(var.velero_restore_mode_only, "false")
    "configuration.backupStorageLocation.bucket"                = try(var.backups_stracc_container_name, "")
    "configuration.backupStorageLocation.config.resourceGroup"  = try(var.backups_rg_name, "")
    "configuration.backupStorageLocation.config.storageAccount" = try(var.backups_stracc_name, "")
    "configuration.backupStorageLocation.name"                  = "default"
    "configuration.provider"                                    = "azure"
    "configuration.volumeSnapshotLocation.config.resourceGroup" = try(var.backups_rg_name, "")
    "configuration.volumeSnapshotLocation.name"                 = "default"
    "credentials.existingSecret"                                = try(kubernetes_secret.velero.metadata[0].name, "")
    "credentials.useSecret"                                     = "true"

    # Use restic for filesystembackup
    "deployRestic"                                              = "true"

    "env.AZURE_CREDENTIALS_FILE"                                = "/credentials"
    "metrics.enabled"                                           = "true"
    "rbac.create"                                               = "true"

    # schedule automated backups
    "schedules.daily.schedule"                                  = "0 23 * * *"
    "schedules.daily.template.includedNamespaces"               = "{*}"
    "schedules.daily.template.snapshotVolumes"                  = "true"
    "schedules.daily.template.ttl"                              = "240h"

    "serviceAccount.server.create"                              = "true"
    "snapshotsEnabled"                                          = "true"

    "initContainers[0].name"                                    = "velero-plugin-for-azure"
    "initContainers[0].image"                                   = "velero/velero-plugin-for-microsoft-azure:v1.1.1"
    "initContainers[0].volumeMounts[0].mountPath"               = "/target"
    "initContainers[0].volumeMounts[0].name"                    = "plugins"

    # Uncomment to install CSI Driver Plugin
    #"initContainers[1].name"                                    = "velero-plugin-for-csi"
    #"initContainers[1].image"                                   = "velero/velero-plugin-for-csi:v0.1.1"
    #"initContainers[1].volumeMounts[0].mountPath"               = "/target"
    #"initContainers[1].volumeMounts[0].name"                    = "plugins"
    #"features"                                                  = "EnableCSI"
    
    "image.repository"                                          = "velero/velero"
    "image.tag"                                                 = "v1.4.0"
    "image.pullPolicy"                                          = "IfNotPresent"
    
    # Uncomment to use Managed identity with velero instead of service principal, does not work with restic (filesystembackup)
    #"podAnnotations.aadpodidbinding"                            = local.velero_identity_name
    #"podLabels.aadpodidbinding"                                 = local.velero_identity_name
  }

```







