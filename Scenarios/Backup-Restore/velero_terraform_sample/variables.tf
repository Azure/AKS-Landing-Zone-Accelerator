#############
# VARIABLES #
#############

variable "region" {
    default = "WestEurope"

}

variable "velero_namespace" {
    default = "velero"

}

variable "backups_rg_name" {
    default = "backups-aks1"

}

variable "backups_region" {
    default = "NorthEurope"

}

variable "backups_stracc_name" {
    default = "backupsveleroaks1"

}

variable "backups_stracc_container_name" {
    default = "velero"

}

variable "tags" {
  type = map(string)

  default = {
    project = "cs-aks"
  }
}

##########################
# Velero variables
##########################

variable "velero_values" {
  description = <<EOVV
Settings for Velero helm chart:
```
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
```
EOVV
  type        = map(string)
  default     = {}
}

variable "velero_chart_version" {
  description = "Velero helm chart version to use"
  type        = string
  default     = "2.29.3"
}

variable "velero_chart_repository" {
  description = "URL of the Helm chart repository"
  type        = string
  default     = "https://vmware-tanzu.github.io/helm-charts"
}



##########################
# AKS Cluster variables
##########################

variable "network_profile" {
  description = "Variables defining the AKS network profile config"
  type = object({
    network_plugin     = string
    network_policy     = string
    dns_service_ip     = string
    docker_bridge_cidr = string
    service_cidr       = string
    load_balancer_sku  = string
  })
  default = {
    network_plugin     = "azure"
    network_policy     = "azure"
    dns_service_ip     = "10.3.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.3.0.0/24"
    load_balancer_sku  = "standard"
  }
}
