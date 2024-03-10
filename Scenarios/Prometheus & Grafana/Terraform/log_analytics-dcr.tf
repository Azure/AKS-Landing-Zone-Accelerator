resource "azurerm_monitor_data_collection_rule" "dcr-log-analytics" {
  name                        = "dcr-log-analytics"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce-log-analytics.id
  kind                        = "Linux"
  depends_on                  = [time_sleep.wait_60_seconds]

  destinations {
    log_analytics {
      name                  = "log-analytics"
      workspace_resource_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default", "Microsoft-Syslog"]
    destinations = ["log-analytics"]
  }

  data_sources {
    syslog {
      name           = "syslog-data-source"
      facility_names = ["*"] # ["auth", "authpriv", "cron", "daemon", "mark", "kern", "local0", "local1", "local2",  "local3", "local4", "local5", "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
      log_levels     = ["Debug", "Info", "Notice", "Warning", "Error", "Critical", "Alert", "Emergency", ]
      streams        = ["Microsoft-Syslog"]
    }
    extension {
      extension_name = "ContainerInsights"
      name           = "ContainerInsightsExtension"
      streams        = ["Microsoft-ContainerInsights-Group-Default"]
      extension_json = jsonencode(
        {
          dataCollectionSettings = {
            enableContainerLogV2   = true
            interval               = "1m"
            namespaceFilteringMode = "Include" # "Exclude" "Off"
            namespaces             = ["kube-system", "default"]
          }
        }
      )
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra-dcr-log-analytics-aks" {
  name                    = "dcra-dcr-log-analytics-aks"
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr-log-analytics.id
}

# DCR creation should be started about 60 seconds after the Log Analytics workspace is created
# This is a workaround, could be fixed in the future
resource "time_sleep" "wait_60_seconds" {
  create_duration = "60s"
  depends_on      = [azurerm_log_analytics_workspace.workspace]
}
