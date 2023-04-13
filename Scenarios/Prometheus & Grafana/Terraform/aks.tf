# aks cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg_aks_cluster.location
  resource_group_name = azurerm_resource_group.rg_aks_cluster.name
  dns_prefix          = "aks"
  kubernetes_version  = "1.25.5"

  default_node_pool {
    name       = "default"
    node_count = "3"
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.workspace.id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      monitor_metrics
    ]
  }
}
