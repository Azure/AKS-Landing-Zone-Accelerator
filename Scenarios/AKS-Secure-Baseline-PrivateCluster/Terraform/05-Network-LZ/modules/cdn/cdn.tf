resource "azurerm_cdn_frontdoor_profile" "cdn-fd" {
  name                = var.caf_basename.azurerm_cdn_frontdoor_profile
  resource_group_name = var.rg
  sku_name            = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "cdn-ep" {
  name                     = var.caf_basename.azurerm_cdn_frontdoor_endpoint
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn-fd.id
}

resource "azurerm_monitor_diagnostic_setting" "cdn" {
  name                           = replace(var.caf_basename.azurerm_monitor_diagnostic_setting, "amds", "cdnamds")
  target_resource_id             = azurerm_cdn_frontdoor_profile.cdn-fd.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "allLogs"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }
}

##########################################################
## Common Naming Variable
##########################################################

variable "caf_basename" {}

####
#### Input variables
####

variable "rg" {

}

variable "log_analytics_workspace_id" {

}
