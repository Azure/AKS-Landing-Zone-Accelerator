
#############
# RESOURCES #
#############

# Resource Group for AKS Components
# This RG uses the same region location as the Landing Zone Network. 
resource "azurerm_resource_group" "rg-aks" {
  name     = "${data.terraform_remote_state.existing-lz.outputs.lz_rg_name}-aks"
  location = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
}

# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {
  name                = "mi-${var.prefix}-aks-cp"
  resource_group_name = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
}

# Role Assignments for Control Plane MSI

resource "azurerm_role_assignment" "aks-to-rt" {
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_rt_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}

resource "azurerm_role_assignment" "aks-to-vnet" {
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id

}

# Log Analytics Workspace for Cluster

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "aks-la-01"
  resource_group_name           = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster

module "aks" {
  source = "./modules/aks"
  depends_on = [
    azurerm_role_assignment.aks-to-vnet
  ]

  resource_group_name           = azurerm_resource_group.rg-aks.name
  location            = azurerm_resource_group.rg-aks.location
  prefix              = "aks-${var.prefix}"
  net_plugin          = var.net_plugin
  vnet_subnet_id = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  mi_aks_cp_id           = azurerm_user_assigned_identity.mi-aks-cp.id
  la_id = azurerm_log_analytics_workspace.aks.id
  gateway_name = data.terraform_remote_state.existing-lz.outputs.gateway_name
  gateway_id = data.terraform_remote_state.existing-lz.outputs.gateway_id

}

# These role assignments grant the groups made in "03-AAD" access to use
# The AKS cluster. 
resource "azurerm_role_assignment" "appdevs_user" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.terraform_remote_state.aad.outputs.appdev_object_id
}

resource "azurerm_role_assignment" "aksops_admin" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.terraform_remote_state.aad.outputs.aksops_object_id
}

# This role assigned grants the current user running the deployment admin rights
# to the cluster. In production, you should use just the AAD groups (above).
resource "azurerm_role_assignment" "aks_rbac_admin" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id

}

# Role Assignment to Azure Container Registry from AKS Cluster
# This must be granted after the cluster is created in order to use the kubelet identity.

resource "azurerm_role_assignment" "aks-to-acr" {
  scope                = data.terraform_remote_state.aks-support.outputs.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_id

}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.

resource "azurerm_role_assignment" "agic_appgw" {
  scope                = data.terraform_remote_state.existing-lz.outputs.gateway_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.agic_id

}






