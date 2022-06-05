# Monitoring Velero with Azure 

## Velero Monitoring Metrics

Velero exposes [Metrics](https://github.com/vmware-tanzu/velero/blob/main/pkg/metrics/metrics.go) for monitoring, available for scrapping with a tool such as Prometheus.


On Azure, You don't need to setup your own Prometheus server: Azure Container Insights knows how to scrape Prometheus Metrics, and you can export your metrics to Azure seamlessly.

![azure-container-insights-prometheus](./media/monitoring-kubernetes-architecture.png)

Read the documentation on Prometheus Integration: 
https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-prometheus-integration

