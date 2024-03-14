output "prometheus_query_endpoint" {
  value = azurerm_monitor_workspace.prometheus.query_endpoint
}

output "garafana_dashboard_endpoint" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}