## Introduction

This helps in configuring your Azure Kubernetes Service (AKS) cluster to send data to Azure Monitor managed service for Prometheus. 

When you configure your AKS cluster to send data to Azure Monitor managed service for Prometheus, a containerized version of the Azure Monitor agent is installed with a metrics extension. 
<i>You just need to specify the Azure Monitor workspace that the data should be sent to.</i>

## Prerequisites

- You must either have an [Azure Monitor workspace](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview) or [create a new one](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview).
- The cluster must use [managed identity authentication](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-overview).
- The following resource providers must be registered in the subscription of the AKS cluster and the Azure Monitor Workspace.
  - Microsoft.ContainerService
  - Microsoft.Insights
  - Microsoft.AlertsManagement
- Register the AKS-PrometheusAddonPreview feature flag in the Azure Kubernetes clusters subscription with the following command in Azure CLI: az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview.
- The aks-preview extension needs to be installed using the command az extension add --name aks-preview. 
- Azure CLI version 2.41.0 or higher is required for this feature.

## Implementation

#### Login into Azure CLI  

```bash
  az login
```

#### Update Subscription

```bash
  az account set --subscription ""
```

#### Register Feature

```bash
  az feature register --namespace Microsoft.ContainerService --name AKS-PrometheusAddonPreview
```

#### Add preview-extension

```bash
  az extension add --name aks-preview
```

#### Enable AzureMonitorMetrics

```bash
  az aks update --enable-azuremonitormetrics -n "" -g ""
```

