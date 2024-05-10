resource "azurerm_monitor_data_collection_endpoint" "dce-prometheus" {
  name                          = "dce-prometheus"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  kind                          = "Linux"
  public_network_access_enabled = true
}

# not required
resource "azurerm_monitor_data_collection_rule_association" "dcra-dce-prometheus-aks" {
#   name                        = "configurationAccessEndpoint" # "dcra-dce-prometheus-aks" #  # name is required when data_collection_rule_id is specified. And when data_collection_endpoint_id is specified, the name is populated with configurationAccessEndpoint
  target_resource_id          = azurerm_kubernetes_cluster.aks.id
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-prometheus.id
}