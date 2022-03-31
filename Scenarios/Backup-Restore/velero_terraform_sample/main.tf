#########################################
#Reference existing resources
data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

data "azurerm_kubernetes_cluster" "aks" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  name                = "primary-aks1"
  resource_group_name = "primary-aks1"
}

data "azurerm_kubernetes_cluster" "aks_dr" {
  depends_on = [azurerm_kubernetes_cluster.aks_dr]
  name                = "aks-dr"
  resource_group_name = "aks-dr"
}


data "azurerm_resource_group" "velero" {
  depends_on = [azurerm_resource_group.aks1_backups]
  name  = var.backups_rg_name
}


data "azurerm_storage_account" "velero" {
  depends_on = [azurerm_storage_account.aks1_backups]
  #name  = var.backups_stracc_name
  name  = "${local.random_stracc_name}"
  resource_group_name  = var.backups_rg_name
}



 #Prepare Service principal used by velero/restric 
data "azuread_service_principal" "velero_sp" {
  display_name = "sp-velero-aks1"
}

#########################################
#Create Resources

resource "azuread_service_principal_password" "velero_sp_password" {
  service_principal_id = data.azuread_service_principal.velero_sp.object_id
}


###Create Role Assignments for velero sp

#Primary AKS
resource "azurerm_role_assignment" "sp_velero_aks_node_rg" {
  scope                = format("/subscriptions/%s/resourceGroups/%s", data.azurerm_subscription.current.subscription_id, data.azurerm_kubernetes_cluster.aks.node_resource_group)
  principal_id         = data.azuread_service_principal.velero_sp.object_id
  role_definition_name = "Contributor"
}

#Secondary / backup AKS
resource "azurerm_role_assignment" "sp_velero_aks_dr_node_rg" {
  scope                = format("/subscriptions/%s/resourceGroups/%s", data.azurerm_subscription.current.subscription_id, data.azurerm_kubernetes_cluster.aks_dr.node_resource_group)
  principal_id         = data.azuread_service_principal.velero_sp.object_id
  role_definition_name = "Contributor"
}


resource "azurerm_role_assignment" "sp_velero_backup_storage" {
  scope                = data.azurerm_storage_account.velero.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.velero_sp.object_id
}

resource "azurerm_role_assignment" "sp_velero_backup_storage_key_operator" {
  scope                = data.azurerm_storage_account.velero.id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = data.azuread_service_principal.velero_sp.object_id
}

resource "azurerm_role_assignment" "sp_velero_backup_rg" {
  scope                = data.azurerm_resource_group.velero.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.velero_sp.object_id
}



#Deploy Velero on source cluster AKS1
module "velero" {
  depends_on = [azurerm_kubernetes_cluster.aks]

  source = "./modules/velero"

  providers = {
    kubernetes = kubernetes.aks-module
    helm       = helm.aks-module
  }

  backups_region       = var.backups_region
  backups_rg_name           = var.backups_rg_name
  #backups_stracc_name           = var.backups_stracc_name
  backups_stracc_name  = "${local.random_stracc_name}"
  backups_stracc_container_name           = var.backups_stracc_container_name
  aks_nodes_resource_group_name = data.azurerm_kubernetes_cluster.aks.node_resource_group
  
  velero_namespace        = var.velero_namespace
  velero_chart_repository = var.velero_chart_repository
  velero_chart_version    = var.velero_chart_version
  velero_values           = var.velero_values
  velero_restore_mode_only           = "false"
  velero_default_volumes_to_restic    = "true" #use restic (file copy) by default for backups (no volume snapshots)


  velero_sp_tenantID = data.azurerm_client_config.current.tenant_id 
  velero_sp_clientID = data.azuread_service_principal.velero_sp.application_id 
  velero_sp_clientSecret = azuread_service_principal_password.velero_sp_password.value 
}



#Deploy Velero on target restore cluster, referencing the same RG and storage for backups
module "veleroaksdr" {
  depends_on = [azurerm_kubernetes_cluster.aks_dr]

  source = "./modules/velero"

  providers = {
    kubernetes = kubernetes.aksdr-module
    helm       = helm.aksdr-module
  }

  backups_region       = var.backups_region
  backups_rg_name           = var.backups_rg_name
  #backups_stracc_name           = var.backups_stracc_name
  backups_stracc_name  = "${local.random_stracc_name}"
  backups_stracc_container_name           = var.backups_stracc_container_name
  aks_nodes_resource_group_name = data.azurerm_kubernetes_cluster.aks_dr.node_resource_group
  
  velero_namespace        = var.velero_namespace
  velero_chart_repository = var.velero_chart_repository
  velero_chart_version    = var.velero_chart_version
  velero_values           = var.velero_values
  velero_restore_mode_only           = "false"
  velero_default_volumes_to_restic    = "true" #use restic (file copy) by default for backups (no volume snapshots)


  velero_sp_tenantID = data.azurerm_client_config.current.tenant_id 
  velero_sp_clientID = data.azuread_service_principal.velero_sp.application_id 
  velero_sp_clientSecret = azuread_service_principal_password.velero_sp_password.value 
}
