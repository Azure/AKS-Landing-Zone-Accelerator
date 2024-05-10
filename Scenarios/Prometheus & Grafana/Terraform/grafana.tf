resource "azurerm_dashboard_grafana" "grafana" {
  name                              = "azure-grafana-${var.prefix}"
  resource_group_name               = azurerm_resource_group.rg.name
  location                          = azurerm_resource_group.rg.location
  sku                               = "Standard"
  grafana_major_version             = "10"
  zone_redundancy_enabled           = false
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = true
  public_network_access_enabled     = true

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }

  identity {
    type = "SystemAssigned"
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "role_grafana_admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "role_monitoring_data_reader" {
  scope                = azurerm_monitor_workspace.prometheus.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "role_monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.grafana.identity.0.principal_id
}
