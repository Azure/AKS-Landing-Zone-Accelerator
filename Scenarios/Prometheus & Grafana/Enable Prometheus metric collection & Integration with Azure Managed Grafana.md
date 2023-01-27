# Enable Prometheus metric collection & Integration with Azure Managed Grafana

## Introduction

- This guidance helps in configuring your Azure Kubernetes Service (AKS) cluster to send data to Azure Monitor managed service for Prometheus. 

- This will also help in creation of Azure Managed Grafana workspace to link with Azure workspace  


## Prerequisites to create Azure Monitor workspace

- You must either have an [Azure Monitor workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview) or [create a new one](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview).
- The cluster must use [managed identity authentication](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview).
- The following resource providers must be registered in the subscription of the AKS cluster and the Azure Monitor Workspace.
  - Microsoft.ContainerService
  - Microsoft.Insights
  - Microsoft.AlertsManagement
- Register the AKS-PrometheusAddonPreview feature flag in the Azure Kubernetes clusters subscription with the following command in Azure CLI: az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview.
- The aks-preview extension needs to be installed using the command az extension add --name aks-preview. 
- Azure CLI version 2.41.0 or higher is required for this feature. Aks-preview version 0.5.122 or higher is required for this feature. You can check the aks-preview version using the az version command.


> Important : Azure Monitor managed service for Prometheus is intended for storing information about service health of customer machines and applications. It is not intended for storing any data classified as Personal Identifiable Information (PII) or End User Identifiable Information (EUII). We strongly recommend that you do not send any sensitive information (usernames, credit card numbers etc.) into Azure Monitor managed service for Prometheus fields like metric names, label names, or label values
For more details , refer https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-overview
## Enable Prometheus metric collection

> Login into Azure CLI  

```bash
  az login
```

> Update Subscription

```bash
  az account set --subscription "subscription-id"
```

> Register Feature

```bash
  az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview
```

> Add preview-extension

```bash
  az extension add --name aks-preview
```

> Create a new default Azure Monitor workspace. If no Azure Monitor Workspace is specified, then a default Azure Monitor Workspace will be created in the DefaultRG-<cluster_region> following the format DefaultAzureMonitorWorkspace-<mapped_region>. This Azure Monitor Workspace will be in the region specific in Region mappings.

```bash
  az aks update --enable-azuremonitormetrics -n <cluster-name> -g <cluster-resource-group>
```

OR

> Use an existing Azure Monitor workspace. If the Azure Monitor workspace is linked to one or more Grafana workspaces, then the data will be available in Grafana.

```bash
az aks update --enable-azuremonitormetrics -n <cluster-name> -g <cluster-resource-group> --azure-monitor-workspace-resource-id <workspace-name-resource-id>
```

## Grafana integration with Azure Monitor Workspace 


You can also refer [Azure Managed Grafana Instance](https://learn.microsoft.com/en-us/azure/managed-grafana/quickstart-managed-grafana-cli) for additional information

This includes the steps that are mentioned below.

1. Create an Azure Managed Grafana instance using the Azure CLI 
2. Grafana integration with Azure Monitor Workspace


> Prerequisites
- Azure Subscription
- Minimum required role to create an instance: resource group Contributor.
- Minimum required role to access an instance: resource group Owner.

> Implementation

1. Create an Azure Managed Grafana workspace

```bash
az grafana create --name <managed-grafana-resource-name> --resource-group <resourcegroupname> -l <Location>
```

**Note:** that Azure Managed Grafana workspace is available only in specific regions. Before deployment , please choose the appropriate region


Now let’s check if you can access your new Managed Grafana instance. Take note of the endpoint URL ending by eus.grafana.azure.com, listed in the CLI output. 

![Grafana Dashboard](https://user-images.githubusercontent.com/50182145/215081171-da0d9b79-a3ec-4408-9fad-3eadc2e1a0d5.png)


**Note**  : Azure Managed Grafana does not support connecting with personal Microsoft accounts currently. Please refer for additional information https://learn.microsoft.com/en-us/azure/managed-grafana/quickstart-managed-grafana-cli

2. Grafana integration with Azure Monitor Workspace
The primary method for visualizing Prometheus metrics is [Azure Managed Grafana](https://learn.microsoft.com/en-us/azure/managed-grafana/overview). 

[Connect your Azure Monitor workspace to a Grafana workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview#link-a-grafana-workspace) – To use it as a data source in a Grafana dashboard. You then have access to multiple prebuilt dashboards that use Prometheus metrics and the ability to create any number of custom dashboards.

> Below is the process to accomplish the same

- Open the Azure Monitor workspace menu in the Azure portal.
- Select your workspace.
- Click Linked Grafana workspaces.
- Select a Grafana workspace.
