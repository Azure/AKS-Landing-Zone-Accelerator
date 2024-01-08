# Create resources for the AKS Cluster

The following will be created:

* AKS Cluster with KeyVault (preview), AGIC and monitoring addons
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

- Microsoft.ContainerService
- EnablePodIdentityPreview
- AKS-AzureKeyVaultSecretsProvider
- Microsoft.OperationsManagement
- Microsoft.OperationalInsights
- EncryptionAtHost

Here is a list with all required providers or features to be registered:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
az feature register --namespace Microsoft.Compute --name EncryptionAtHost
```

> :warning: Don't move ahead to the next steps until all providers are registered.

There are two groups you need to change in parameters-main.json: 
    - Admin group which will grant the role "Azure Kubernetes Service Cluster Admin Role". The parameter name is: aksadminaccessprincipalId. 
    - Dev/User group which will grant "Azure Kubernetes Service Cluster User Role". The parameter name is: aksuseraccessprincipalId.

## AKS Networking Choices

You can choose which AKS network plugin you want to use when deploying the cluster: Azure CNI or Kubenet. To learn more about both options, you can refer to the [Azure CNI VS Kubenet](#Azure-CNI-VS-Kubenet) section at the bottom of this page.

**Please note: If you are new to Kubernetes, we recommend for you to choose Azure CNI Networking to avoid the extra complexity of routing.**

## Deploy the cluster

Review "**parameters-main.json**" file and update the values as required. Please make sure to update the Microsoft Entra ID Group IDs with ones created in Step 02 and kubernetesVersion in the parameters file. Once the files are updated, deploy using az cli or Az PowerShell (code snippets are below).

   > :warning: There are two groups you need to change in parameters-main.json:
   >
   > * Admin group which will grant the role "Azure Kubernetes Service Cluster Admin Role". The parameter name is: *aksadminaccessprincipalId*.
   > * Dev/User group which will grant "Azure Kubernetes Service Cluster User Role". The parameter name is: *aksadminaccessprincipalId*.

The Kubernetes community releases minor versions roughly every three months. AKS has it own supportability policy based in the community releases. Before proceeding with the deployment, check the latest version reviewing the [supportability doc](https://learn.microsoft.com/azure/aks/supported-kubernetes-versions). You can also check the latest version by using the following command:

```azurecli
az aks get-versions -l <region>
```

# [CLI](#tab/CLI)

```azurecli
acrName=$(az deployment sub show -n "ESLZ-AKS-Supporting" --query properties.outputs.acrName.value -o tsv)
keyVaultName=$(az deployment sub show -n "ESLZ-AKS-Supporting" --query properties.outputs.keyvaultName.value -o tsv)
```

### Reference: Follow the below steps if you are going with the Azure CNI Networking option

```
az deployment sub create -n "ESLZ-AKS-CLUSTER" -l $REGION -f main.bicep -p parameters-main.json -p acrName=$acrName -p keyvaultName=$keyVaultName -p kubernetesVersion=1.25.5 -p networkPlugin=azure
```

### Reference: Follow the below steps if you are going with the Kubenet option

Step 1:

[How to setup networking between Application Gateway and AKS](https://azure.github.io/application-gateway-kubernetes-ingress/how-tos/networking/)

Step 2: (Optional - *if you don't do this, you'll have to manually update the route table after scaling changes in the cluster*)

[Using AKS kubenet egress control with AGIC](https://github.com/Welasco/AKS-AGIC-UDR-AutoUpdate)

```
az deployment sub create -n "ESLZ-AKS-CLUSTER" -l $REGION -f main.bicep -p parameters-main.json -p acrName=$acrName -p keyvaultName=$keyVaultName -p kubernetesVersion=1.22.6 -p networkPlugin=kubenet
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile main.bicep -TemplateParameterFile parameters-main.json -Location $REGION -Name ESLZ-AKS-CLUSTER
```

## Azure CNI VS Kubenet

If you are using the Azure network plugin, each pod in the cluster will have an IP from the AKS Subnet CIDR. This allows Application Gateway and any other external service to reach the pod using this IP.

For kubenet plugin, all the PODs get an IP address from POD-CIDR within the cluster. To route traffic to these pods, the TCP/UDP flow must go to the node where the pod resides. By default, AKS will maintain the User Defined Route (UDR) associated with the subnet where it belongs to always be updated with the CIDR /24 of the respective POD/Node IP address.

Currently Application Gateway does not support any scenario where a route 0.0.0.0/0 needs to be redirected through any virtual appliance, a hub/spoke virtual network, or on-premises (forced tunnelling). Since Application Gateway doesn't support UDR with a route 0.0.0.0/0 and it's a requirement for AKS egress control you cannot use the same route table for both subnets (Application Gateway subnet and AKS subnet).

This means the Application Gateway doesn't know how to route the traffic of a POD backend pool in a AKS cluster when you are using the kubenet plugin. Because of this limitation, you cannot associate the default AKS UDR to the Application Gateway subnet since an AKS cluster with egress controller requires a 0.0.0.0/0 route. It's possible to create a manual route table to address this problem but once a node scale operation happens, the route needs to be updated again and this would require a manual update.

For the purpose of this deployment when used with kubenet a UDR will be created during the deployment pointing the expected address prefix (CIDR) to the respective AKS worker node. This UDR will not be auto managed and in case of a cluster scale operation it should be manually updated.

It's also possible to use an Azure external solution to watch the scaling operations and auto-update the routes using Azure Automation, Azure Functions or Logic Apps.

[Use kubenet networking with your own IP address ranges in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/azure/aks/configure-kubenet)
[Application Gateway infrastructure configuration](https://learn.microsoft.com/azure/application-gateway/configuration-infrastructure#supported-user-defined-routes)

:arrow_forward: [Deploy a Basic Workload](./07-workload.md)
