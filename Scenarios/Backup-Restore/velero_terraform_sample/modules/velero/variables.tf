variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the resource."
  default = {
    "made-by" = "terraform"
  }
}

variable "backups_rg_name" {
  description = "RG to store backups and volume snapshots"
  type        = string
}

variable "backups_stracc_name" {
  description = "storage account to store backup files and configuration"
  type        = string
  default     = "velero"
}

variable "backups_stracc_container_name" {
  description = "storage account to store backup files and configuration"
  type        = string
  default     = "velero"
}

variable "velero_sp_tenantID" {
  description = "Tenant ID for service pricinpal used by velero/restic"
  type        = string
  default = ""
}

variable "velero_sp_clientID" {
  description = "Client ID for service pricinpal used by velero/restic"
  type        = string
  default = ""
}

variable "velero_default_volumes_to_restic" {
  description = "Use restic (file copy) by default to backup all volumes"
  type        = string
  default = "true"
}


variable "velero_restore_mode_only" {
  description = "Access mode for velero : backup/restore or restore only"
  type        = string
  default = "false"
}

variable "velero_sp_clientSecret" {
  description = "Client Secret for service pricinpal used by velero/restic"
  type        = string
  default = ""
}

variable "aks_nodes_resource_group_name" {
  description = "Name of AKS nodes resource group"
  type        = string
}

variable "velero_chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://vmware-tanzu.github.io/helm-charts"
}


variable "velero_values" {
  description = <<EOVV
Settings for Velero helm chart

map(object({ 
  configuration.backupStorageLocation.bucket                = string 
  configuration.backupStorageLocation.config.resourceGroup  = string 
  configuration.backupStorageLocation.config.storageAccount = string 
  configuration.backupStorageLocation.name                  = string 
  configuration.provider                                    = string 
  configuration.volumeSnapshotLocation.config.resourceGroup = string 
  configuration.volumeSnapshotLocation.name                 = string 
  credential.exstingSecret                                  = string 
  credentials.useSecret                                     = string 
  deployRestic                                              = string 
  env.AZURE_CREDENTIALS_FILE                                = string 
  metrics.enabled                                           = string 
  rbac.create                                               = string 
  schedules.daily.schedule                                  = string 
  schedules.daily.template.includedNamespaces               = string 
  schedules.daily.template.snapshotVolumes                  = string 
  schedules.daily.template.ttl                              = string 
  serviceAccount.server.create                              = string 
  snapshotsEnabled                                          = string 
  initContainers[0].name                                    = string 
  initContainers[0].image                                   = string 
  initContainers[0].volumeMounts[0].mountPath               = string 
  initContainers[0].volumeMounts[0].name                    = string 
  image.repository                                          = string 
  image.tag                                                 = string 
  image.pullPolicy                                          = string
  podAnnotations.aadpodidbinding                            = string
  podLabels.aadpodidbinding                                 = string

}))
EOVV
  type        = map(string)
  default     = {}
}

#variable "velero_azureidentity_name" {
#  description = "The name of the User Assigned identity for velero for a given AKS cluster"
#  type        = string
#  #default     = "velero"
#}

variable "velero_namespace" {
  description = "Kubernetes namespace in which to deploy Velero"
  type        = string
  default     = "velero"
}

variable "velero_chart_version" {
  description = "Velero helm chart version to use"
  type        = string
  default     = "2.29.3"
}



variable "backups_region" {
  description = "Azure region to use"
  type        = string
}


variable "environment" {
  description = "Project environment"
  type        = string
  default     = "DEV"
}

