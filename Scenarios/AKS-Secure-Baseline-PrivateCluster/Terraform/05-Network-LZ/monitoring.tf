# Log Analytics for AKS
resource "azurerm_log_analytics_workspace" "spokeLA" {
  name                = replace(module.CAFResourceNames.names.azurerm_log_analytics_workspace, "log", "${var.lz_prefix}log")
  location            = azurerm_resource_group.spoke-rg.location
  resource_group_name = azurerm_resource_group.spoke-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 # has to be between 30 and 730

  daily_quota_gb = 10

  tags = var.tags
}

#############
## OUTPUTS ##
#############
# These outputs are used by later deployments
output "la_id" {
  value = azurerm_log_analytics_workspace.spokeLA.id
}
