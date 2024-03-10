resource "azurerm_monitor_data_collection_rule" "dcr-prometheus" {
  name                        = "dcr-prometheus"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-prometheus.id
  kind                        = "Linux"
  description                 = "DCR for Azure Monitor Metrics Profile (Managed Prometheus)"

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }

  destinations {
    monitor_account {
      monitor_account_id = azurerm_monitor_workspace.prometheus.id
      name               = azurerm_monitor_workspace.prometheus.name
    }
  }

  data_flow {
    streams      = ["Microsoft-PrometheusMetrics"]
    destinations = [azurerm_monitor_workspace.prometheus.name]
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra-dcr-prometheus-aks" {
  name                    = "dcra-dcr-prometheus-aks"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-prometheus.id
  description             = "Association of DCR. Deleting this association will break the data collection for this AKS Cluster."
}
