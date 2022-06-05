# Monitoring Velero with Azure 

## Velero Monitoring Metrics

Velero exposes [Metrics](https://github.com/vmware-tanzu/velero/blob/main/pkg/metrics/metrics.go) for monitoring, available for scrapping with a tool such as Prometheus.


On Azure, You don't need to setup your own Prometheus server: Azure Container Insights knows how to scrape Prometheus Metrics, and you can export your metrics to Azure seamlessly.

![azure-container-insights-prometheus](../media/monitoring-kubernetes-architecture.png)

Read the documentation on Prometheus Integration: 
https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-prometheus-integration


## How to enable Azure Container Insights for scraping Prometheus metrics ?

To enable scraping with Container insights, you simply need to configure a ConfigMap related to metrics & data collection.


You can find [an example, in this repository](./container-azm-ms-agentconfig.yaml) for testing purposes (we recommend to download the latest version from the documentation link above).

In this example, we simply *enable monitoring_kubernetes_pods*, and that's it !
```bash
        monitor_kubernetes_pods = true
        ## Restricts Kubernetes monitoring to namespaces for pods that have annotations set and are scraped using the monitor_kubernetes_pods setting.
        ## This will take effect when monitor_kubernetes_pods is set to true
        # ex. monitor_kubernetes_pods_namespaces = ["velero"]
```


