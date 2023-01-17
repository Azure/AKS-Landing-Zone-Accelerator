# Using Azure ML on a Secure AKS Cluster

This architectural pattern describes how to deployment an AKS cluster to be used by Azure ML. This follows the guiding tenets of the [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/). 

At it's core, this pattern provides a prescriptive way to use Azure Marchine Learning in a private AKS cluster using the following topology:

 - Private Cluster
 - User Defined Routes
 - Hub-Spoke Topology
 - Jumpbox
 - Azure Firewall
 
In the above mentioned scenario the desired outcome is to apply these changes without affecting the applications and/workloads hosted in the AKS cluster.
This pattern is also at the basis for the mission critical deployment of workloads on AKS, the main difference is that in that scenario, the resiliency and AKS distribution in multiple regions are the main drivers and elements of the solution.

## Procedure

### Create your Azure Kubernetes Service (AKS) cluster and Azure Container Registry (ACR)

1. Use the [AKS Construction Helper](https://azure.github.io/AKS-Construction/) to setup your target AKS cluster. Use this [predefined configuration](https://azure.github.io/AKS-Construction/?secure=private&addons.ingress=none&deploy.location=EastUS&deploy.deployItemKey=deployTf&cluster.SystemPoolType=Standard&cluster.AksPaidSkuForSLA=false&cluster.osDiskType=Ephemeral&cluster.vmSize=Standard_DS4_v2&cluster.autoscale=true&net.networkPlugin=kubenet&cluster.availabilityZones=yes&addons.networkPolicy=none&net.vnet_opt=custom&net.podCidr=10.174.0.0%2F17&net.serviceCidr=10.174.128.0%2F17&net.dnsServiceIP=10.174.128.128) to make sure you configure it appropriately or use the Azure CLI snippets below.

```bash
# Log in
az login 

# Create Resource Group
az group create -l EastUS -n az-k8s-eizw-rg

# Deploy template with in-line parameters
az deployment group create -g az-k8s-eizw-rg  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.9.6/main.json --parameters \
	resourceName=az-k8s-eizw \
	upgradeChannel=stable \
	SystemPoolType=Standard \
	agentVMSize=Standard_DS4_v2 \
	agentCountMax=20 \
	custom_vnet=true \
	serviceCidr=10.174.128.0/17 \
	dnsServiceIP=10.174.128.128 \
	bastion=true \
	enable_aad=true \
	AksDisableLocalAccounts=true \
	enableAzureRBAC=true \
	adminPrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	registries_sku=Premium \
	acrPushRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	azureFirewalls=true \
	privateLinks=true \
	omsagent=true \
	retentionInDays=30 \
	networkPolicy=calico \
	azurepolicy=deny \
	networkPlugin=kubenet \
	podCidr=10.174.0.0/17 \
	availabilityZones="[\"1\",\"2\",\"3\"]" \
	enablePrivateCluster=true \
	keyVaultAksCSI=true \
	keyVaultCreate=true \
	keyVaultOfficerRolePrincipalId=$(az ad signed-in-user show --query id --out tsv) \
	acrPrivatePool=true
```
