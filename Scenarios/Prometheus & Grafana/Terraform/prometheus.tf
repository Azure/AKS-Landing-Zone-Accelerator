# https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview?tabs=resource-manager#create-an-azure-monitor-workspace
# https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/azapi_resource

resource "azapi_resource" "prometheus" {
  type      = "microsoft.monitor/accounts@2021-06-03-preview"
  name      = var.prometheus_name
  parent_id = azurerm_resource_group.rg_monitoring.id
  location  = azurerm_resource_group.rg_monitoring.location
}