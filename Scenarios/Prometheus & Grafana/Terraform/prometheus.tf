resource "azurerm_monitor_workspace" "prometheus" {
  name                          = "azure-prometheus"
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  public_network_access_enabled = true
}

resource "azurerm_role_assignment" "role_monitoring_data_reader_me" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}