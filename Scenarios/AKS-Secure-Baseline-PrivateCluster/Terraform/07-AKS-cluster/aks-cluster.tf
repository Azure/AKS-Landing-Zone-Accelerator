
#############
# LOCALS #
#############

/*
The following map enables the deployment of multiple clusters, as example you can use to deploy two clusters for the blue green deployment, instead if you need to deploy just one AKS cluster for sample and standard deployment then you you can configure a map with only one object.
locals {
  Map of the AKS Clusters to deploy
  aks_clusters = {
    "aks_blue" = {
      prefix used to configure unique names and parameter values
      name_prefix="blue"
      Boolean flag that enable or disable the deployment of the specific AKS cluster
      aks_turn_on=true
      The kubernetes version to use on the cluster
      k8s_version="1.25.5"
      Reference Name to the Application gateway that need to be associaated to the AKS Cluster with the AGIC addo-on
      appgw_name="lzappgw-blue"
    },
    "aks_green" = {
      name_prefix="green"
      aks_turn_on=false
      k8s_version="1.23.8"
      appgw_name="lzappgw-green"
    }
  }
}

*/
locals {
  aks_clusters = {
    "aks_blue" = {
      name_prefix = "blue"
      aks_turn_on = true
      k8s_version = "1.29"
      appgw_name  = "lzappgw-blue"
    },
    "aks_green" = {
      name_prefix = "green"
      aks_turn_on = false
      k8s_version = "1.29"
      appgw_name  = "lzappgw-green"
    }
  }
}

#############
# RESOURCES #
#############

# MSI for Kubernetes Cluster (Control Plane)
# This ID is used by the AKS control plane to create or act on other resources in Azure.
# It is referenced in the "identity" block in the azurerm_kubernetes_cluster resource.
# Based on the structure of the aks_clusters map is created an identity per each AKS Cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_user_assigned_identity" "mi-aks-cp" {
  for_each            = { for aks_clusters in local.aks_clusters : aks_clusters.name_prefix => aks_clusters if aks_clusters.aks_turn_on == true }
  name                = "mi-${var.prefix}-aks-${each.value.name_prefix}-cp"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
}

# Role Assignments for Control Plane MSI
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks-to-rt" {
  for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_rt_id
  role_definition_name = "Contributor"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "aks-to-vnet" {
  for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = each.value.principal_id

}

# Role assignment to to create Private DNS zone for cluster
# Based on the structure of the aks_clusters map is defined the role assignment per each AKS Cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks-to-dnszone" {
  for_each             = azurerm_user_assigned_identity.mi-aks-cp
  scope                = azurerm_private_dns_zone.aks-dns.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = each.value.principal_id
}

# Log Analytics Workspace for Cluster

resource "azurerm_log_analytics_workspace" "aks" {
  name                = "aks-la-01"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster
# Based on the structure of the aks_clusters map are provisioned multiple AKS Clusters, this is mainly used in the blue green deployment scenario.
module "aks" {
  source              = "./modules/aks"
  for_each            = { for aks_clusters in local.aks_clusters : aks_clusters.name_prefix => aks_clusters if aks_clusters.aks_turn_on == true }
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  prefix              = "aks-${var.prefix}-${each.value.name_prefix}"
  vnet_subnet_id      = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  mi_aks_cp_id        = azurerm_user_assigned_identity.mi-aks-cp[each.value.name_prefix].id
  la_id               = azurerm_log_analytics_workspace.aks.id
  gateway_name        = data.terraform_remote_state.existing-lz.outputs.gateway_name[each.value.appgw_name]
  gateway_id          = data.terraform_remote_state.existing-lz.outputs.gateway_id[each.value.appgw_name]
  private_dns_zone_id = azurerm_private_dns_zone.aks-dns.id
  network_plugin      = try(var.network_plugin, "azure")
  pod_cidr            = try(var.pod_cidr, null)
  k8s_version         = each.value.k8s_version
  depends_on = [
    azurerm_role_assignment.aks-to-vnet,
    azurerm_role_assignment.aks-to-dnszone
  ]
}

# These role assignments grant the groups made in "03-EID" access to use

# The AKS cluster. 
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "appdevs_user" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.terraform_remote_state.aad.outputs.appdev_object_id
}

resource "azurerm_role_assignment" "aksops_admin" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.terraform_remote_state.aad.outputs.aksops_object_id
}

# This role assigned grants the current user running the deployment admin rights
# to the cluster. In production, you should use just the EID groups (above).
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.
resource "azurerm_role_assignment" "aks_rbac_admin" {
  for_each             = module.aks
  scope                = each.value.aks_id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id

}

# Role Assignment to Azure Container Registry from AKS Cluster
# This must be granted after the cluster is created in order to use the kubelet identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "aks-to-acr" {
  for_each             = module.aks
  scope                = data.terraform_remote_state.aks-support.outputs.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = each.value.kubelet_id
}

# Role Assignments for AGIC on AppGW
# This must be granted after the cluster is created in order to use the ingress identity.
# Based on the instances of AKS Clusters deployed are defined the role assignments per each cluster, this is mainly used in the blue green deployment scenario.

resource "azurerm_role_assignment" "agic_appgw" {
  for_each             = module.aks
  scope                = each.value.appgw_id
  role_definition_name = "Contributor"
  principal_id         = each.value.agic_id
}

# Route table to support AKS cluster with kubenet network plugin

resource "azurerm_route_table" "rt" {
  count                         = var.network_plugin == "kubenet" ? 1 : 0
  name                          = "appgw-rt"
  location                      = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  resource_group_name           = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  disable_bgp_route_propagation = false

}

resource "azurerm_subnet_route_table_association" "rt_kubenet_association" {
  count          = var.network_plugin == "kubenet" ? 1 : 0
  subnet_id      = data.terraform_remote_state.existing-lz.outputs.appgw_subnet_id
  route_table_id = azurerm_route_table.rt[count.index].id

  depends_on = [ azurerm_route_table.rt]

}
