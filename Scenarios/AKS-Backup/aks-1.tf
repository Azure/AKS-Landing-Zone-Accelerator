data "azurerm_kubernetes_cluster" "aks-1" {
  name                = var.aksName
  resource_group_name = var.rgLzName
}

data "azurerm_user_assigned_identity" "aks1_identity" {
  name                = split("/", data.azurerm_kubernetes_cluster.aks-1.identity.0.identity_ids[0])[8]
  resource_group_name = var.rgLzName
}

resource "azurerm_role_assignment" "cluster_msi_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_user_assigned_identity.aks1_identity.principal_id
}
