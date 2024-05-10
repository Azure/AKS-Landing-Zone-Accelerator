# not required
resource "azurerm_monitor_data_collection_endpoint" "dce-log-analytics" {
  name                          = "dce-log-analytics"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  public_network_access_enabled = true
  kind                          = "Linux"
}

# # not required
# resource "azurerm_monitor_data_collection_rule_association" "dcra-dce-log-analytics-aks" {
#   name                        = "configurationAccessEndpoint" # name is required when data_collection_rule_id is specified. And when data_collection_endpoint_id is specified, the name is populated with configurationAccessEndpoint
#   target_resource_id          = azurerm_kubernetes_cluster.aks.id
#   data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
# }
