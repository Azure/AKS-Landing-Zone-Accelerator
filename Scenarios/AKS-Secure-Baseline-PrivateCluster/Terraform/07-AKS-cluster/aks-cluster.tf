
#############
# RESOURCES #
#############

# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {
  name                = replace(module.CAFResourceNames.names.azurerm_user_assigned_identity, "msi", "aksmsi")
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
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

# Role assignment to to create Private DNS zone for cluster
resource "azurerm_role_assignment" "aks-to-dnszone" {
  scope                = azurerm_private_dns_zone.aks-dns.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}

# Log Analytics Workspace for Cluster

resource "azurerm_log_analytics_workspace" "aks" {
  name                = replace(module.CAFResourceNames.names.azurerm_log_analytics_workspace, "log", "akslog")
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster

module "aks" {
  source = "./modules/aks"
  depends_on = [
    azurerm_role_assignment.aks-to-vnet,
    azurerm_role_assignment.aks-to-dnszone
  ]

  caf_basename        = module.CAFResourceNames.names
  dns_prefix          = var.dns_prefix
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  vnet_subnet_id      = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  linnp_subnet_id     = data.terraform_remote_state.existing-lz.outputs.aks_linuxnp_subnet_id
  mi_aks_cp_id        = azurerm_user_assigned_identity.mi-aks-cp.id
  la_id               = azurerm_log_analytics_workspace.aks.id
  spoke_la_id         = data.terraform_remote_state.existing-lz.outputs.la_id
  private_dns_zone_id = azurerm_private_dns_zone.aks-dns.id
  aks_admin_group     = data.terraform_remote_state.aad.outputs.aksops_object_id
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

