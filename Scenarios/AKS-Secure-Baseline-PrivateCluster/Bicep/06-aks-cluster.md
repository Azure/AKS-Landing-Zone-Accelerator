# Create resources for the AKS Cluster

The following will be created:

* AKS Cluster with KeyVault (preview) and monitoring addons
* Log Analytics Workspace
* ACR Access to the AKS Cluster
* Updates to KeyVault access policy with AKS keyvault addon

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/06-AKS-cluster" folder

```bash
cd ../06-AKS-cluster
```

To create an AKS cluster that can use the Secrets Store CSI Driver, you must enable the AKS-AzureKeyVaultSecretsProvider feature flag on your subscription. Register the AKS-AzureKeyVaultSecretsProvider feature flag by using the az feature register command, as shown below

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

if not enter the command below to enable it

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
```

It takes a few minutes for the status to show *Registered*. Verify the registration status by using the [az feature list](https://learn.microsoft.com/cli/azure/feature#az_feature_list) command:

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

When ready, refresh the registration of the *Microsoft.ContainerService* resource provider by using the [az provider register](https://learn.microsoft.com/cli/azure/provider#az_provider_register) command:

```bash
az provider register --namespace Microsoft.ContainerService
```

There are a few additional Azure Providers and features that needs to be registered as well. Follow the same steps above for the following providers and features:

* Microsoft.ContainerService
* AKS-AzureKeyVaultSecretsProvider
* Microsoft.OperationsManagement
* Microsoft.OperationalInsights
* EncryptionAtHost

Here is a list with all required providers or features to be registered:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

> :warning: Don't move ahead to the next steps until all providers are registered.

There is one admin group you need to set in main.bicepparam:

* Admin group which will grant the role "Azure Kubernetes Service Cluster Admin Role". The parameter name is: aksAdminAccessPrincipalId.

## AKS Networking Choices

You can choose which AKS network plugin you want to use when deploying the cluster: Azure CNI or Kubenet. To learn more about both options, you can refer to the [Azure CNI VS Kubenet](#azure-cni-vs-kubenet) section at the bottom of this page.

**Please note: If you are new to Kubernetes, we recommend for you to choose Azure CNI Networking to avoid the extra complexity of routing.**

## AKS SKU: Standard vs Automatic

You can choose between two AKS cluster SKUs:

* **Base (Standard)** — The traditional AKS experience with full manual control over node pools, scaling, and configuration. You manage node pools, autoscaler settings, and cluster upgrades explicitly.

* **Automatic** — An opinionated, fully-managed AKS cluster that automates node provisioning (Node Auto Provisioning), scaling (KEDA + VPA), security defaults, and upgrade policies. Best for teams that want a production-ready cluster with minimal operational overhead.

### Key trade-offs

| Aspect | Base (Standard) | Automatic |
| -------- | ---------------- | ----------- |
| **Node management** | Manual node pools with configurable autoscaler | Automatic node provisioning (NAP) |
| **Scaling** | Cluster autoscaler only | KEDA + VPA + NAP |
| **Identity** | User-assigned managed identity | System-assigned managed identity |
| **Upgrades** | Manual or configurable auto-upgrade | Auto-upgrade with maintenance windows |
| **Outbound type** | Load Balancer (configurable) | Managed NAT Gateway |
| **Node resource group** | Unrestricted (default) | ReadOnly |
| **Network plugin** | Azure CNI or Kubenet | Azure CNI (managed) |

To deploy with AKS Automatic, set `aksSkuName=Automatic` in your deployment command.

## Deploy the cluster

Review "**main.bicepparam**" file and update the values as required. Please make sure to update the Microsoft Entra ID group ID with the one created in Step 02 and kubernetesVersion in the parameters file. Once the files are updated, deploy using the Azure CLI or Azure PowerShell (code snippets are below).

   > :warning: Update the admin group in main.bicepparam:
   >
   > * Admin group which will grant the role "Azure Kubernetes Service Cluster Admin Role". The parameter name is: *aksAdminAccessPrincipalId*.

The Kubernetes community releases minor versions roughly every three months. AKS has it own supportability policy based in the community releases. Before proceeding with the deployment, check the latest version reviewing the [supportability doc](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions). You can also check the latest version by using the following command:

```azurecli
az aks get-versions -l $REGION
```

## [CLI](#tab/CLI)

## Reference: Follow the below steps if you are going with the Azure CNI Networking option

```bash
az stack sub create \
  --name "AKS-LZA-CLUSTER" \
  --location $REGION \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters kubernetesVersion=1.33 networkPlugin=azure \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

## Reference: Follow the below steps if you are going with AKS Automatic mode

```bash
az stack sub create \
  --name "AKS-LZA-CLUSTER" \
  --location $REGION \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters kubernetesVersion=1.33 networkPlugin=azure aksSkuName=Automatic \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

## Reference: Follow the below steps if you are going with the Kubenet option

```bash
az stack sub create \
  --name "AKS-LZA-CLUSTER" \
  --location $REGION \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters acrName=$acrName keyVaultName=$keyVaultName kubernetesVersion=1.33 networkPlugin=kubenet \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeploymentStack `
  -Name "AKS-LZA-CLUSTER" `
  -Location $REGION `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.bicepparam `
  -ActionOnUnmanage DetachAll `
  -DenySettingsMode None
```

## Azure CNI VS Kubenet

If you are using the Azure network plugin, each pod in the cluster will have an IP from the AKS Subnet CIDR. This allows Application Gateway for Containers and any other external service to reach the pod using this IP.

For kubenet plugin, all the PODs get an IP address from POD-CIDR within the cluster. To route traffic to these pods, the TCP/UDP flow must go to the node where the pod resides. By default, AKS will maintain the User Defined Route (UDR) associated with the subnet where it belongs to always be updated with the CIDR /24 of the respective POD/Node IP address.

[Use kubenet networking with your own IP address ranges in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/aks/configure-kubenet)

:arrow_forward: [Deploy a Basic Workload](./07-workload.md)
