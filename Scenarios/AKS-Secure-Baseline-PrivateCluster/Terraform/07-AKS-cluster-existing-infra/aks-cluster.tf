
#############
# RESOURCES #
#############

# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {
  name                = "mi-${var.prefix}-aks-cp"
  resource_group_name = var.existing_spoke_vnet_rg_name
  location            = var.existing_spoke_vnet_rg_location
}

# Role Assignments for Control Plane MSI

resource "azurerm_role_assignment" "aks-to-rt" {
  scope                = var.existing_rt_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.mi-aks-cp.principal_id
}

resource "azurerm_role_assignment" "aks-to-vnet" {
  scope                = var.existing_spoke_vnet_id
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
  name                = "aks-la-01"
  resource_group_name = var.existing_spoke_vnet_rg_name
  location            = var.existing_spoke_vnet_rg_location
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

  resource_group_name = var.existing_spoke_vnet_rg_name
  location            = var.existing_spoke_vnet_rg_location
  prefix              = "aks-${var.prefix}"
  vnet_subnet_id      = var.existing_aks_subnet_id
  mi_aks_cp_id        = azurerm_user_assigned_identity.mi-aks-cp.id
  la_id               = azurerm_log_analytics_workspace.aks.id
  gateway_name        = var.existing_gateway_name
  gateway_id          = var.existing_gateway_id
  private_dns_zone_id = azurerm_private_dns_zone.aks-dns.id

}

# These role assignments grant the groups made in "03-AAD" access to use
# The AKS cluster.
resource "azurerm_role_assignment" "appdevs_user" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.existing_appdev_object_id
}

resource "azurerm_role_assignment" "aksops_admin" {
  scope                = module.aks.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.existing_aksops_object_id
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
  scope                = var.existing_container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_id
}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.

resource "azurerm_role_assignment" "agic_appgw" {
  scope                = var.existing_gateway_id
  role_definition_name = "Contributor"
  principal_id         = module.aks.agic_id
}