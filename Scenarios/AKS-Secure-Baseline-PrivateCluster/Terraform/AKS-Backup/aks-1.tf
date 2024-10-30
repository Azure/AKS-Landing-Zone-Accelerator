# resource "azurerm_kubernetes_cluster" "aks-1" {
#   name                = "aks-cluster"
#   location            = azurerm_resource_group.rg-1.location
#   resource_group_name = azurerm_resource_group.rg-1.name
#   dns_prefix          = "aks"
#   kubernetes_version  = "1.30.5"

#   network_profile {
#     network_plugin      = "azure"
#     network_plugin_mode = "overlay"
#   }

#   default_node_pool {
#     name                        = "systempool"
#     temporary_name_for_rotation = "syspool"
#     node_count                  = 3
#     vm_size                     = "standard_b2als_v2"
#     zones                       = [1, 2, 3]
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   lifecycle {
#     ignore_changes = [
#       default_node_pool.0.upgrade_settings
#     ]
#   }
# }

# data "azurerm_kubernetes_cluster" "aks-1" {
#   name                = 
#   resource_group_name = azurerm_kubernetes_cluster.aks-1.resource_group_name
# }

resource "azurerm_role_assignment" "cluster_msi_contributor_on_snap_rg" {
  scope                = azurerm_resource_group.rg-backup.id
  role_definition_name = "Contributor"
  principal_id         = var.aksClusterIdentityPrincipalId
}
