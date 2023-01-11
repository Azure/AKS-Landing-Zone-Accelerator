# Create resources for the AKS Private Cluster

The following will be created:
* AKS Private Clusters
* Log Analytics Workspace
* Managed Identity for AKS Control Plane
* Managed Identity for Application Gateway Ingress Controller
* Managed Identity for the Azure key vault secrets provider add on
* AKS Pod Identity Assignments - OPTIONAL

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/07-AKS-cluster" folder
```bash
cd ../07-AKS-cluster
```

## AKS Networking Choices

You can choose which AKS network plugin you want to deploy the cluster: azure or kubenet.
For the Azure network plugin, each pod in the cluster will have an IP from the AKS Subnet CIDR. This allows Application Gateway and any other external service to reach the pod using this IP.

For kubenet plugin, all the PODs get an IP address from POD-CIDR within the cluster. To route traffic to these pods, the TCP/UDP flow must go to the node where the pod resides. By default, AKS will maintain the User Defined Route (UDR) associated with the subnet where it belongs to always be updated with the CIDR /24 of the respective POD/Node IP address.

Currently Application Gateway does not support any scenario where a route 0.0.0.0/0 needs to be redirected through any virtual appliance, a hub/spoke virtual network, or on-premises (forced tunneling). Since Application Gateway doesn't support UDR with a route 0.0.0.0/0 and it's a requirement for AKS egress control you cannot use the same route table for both subnets (Application Gateway subnet and AKS subnet).

This means the Application Gateway doesn't know how to route the traffic of a POD backend pool in a AKS cluster when you are using the kubenet plugin. Because of this limitation, you cannot associate the default AKS UDR to the Application Gateway subnet since an AKS cluster with egress controller requires a 0.0.0.0/0 route. It's possible to create a manual route table to address this problem but once a node scale operation happens, the route needs to be updated again and this would require a manual update.

For the purpose of this deployment when used with kubenet, a Route Table will be applied to the App gateway subnet during the deployment. You will need to create 3 manual routes inside the route table that point the nodes where the pods reside.

It's also possible to use an Azure external solution to watch the scaling operations and auto-update the routes using Azure Automation, Azure Functions or Logic Apps.

### Reference: Follow steps 1 and 2 below only if you are going with the Kubenet option

Step 1:

[How to setup networking between Application Gateway and AKS](https://azure.github.io/application-gateway-kubernetes-ingress/how-tos/networking/)

Step 2: (Optional - *if you don't do this, you'll have to manually update the route table after scaling changes in the cluster*)

[Using AKS kubenet egress control with AGIC](https://github.com/Welasco/AKS-AGIC-UDR-AutoUpdate)

More info:

[Use kubenet networking with your own IP address ranges in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet)
[Application Gateway infrastructure configuration](https://docs.microsoft.com/en-us/azure/application-gateway/configuration-infrastructure#supported-user-defined-routes)

This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed.  This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo.

Once again, A sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

Once the files are updated, deploy using Terraform Init, Plan and Apply.

```bash
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
```

```bash
terraform plan
```

```bash
terraform apply
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.

## The Key Vault Add-On

We start by creating some environment variables. The AKS cluster name can be found in the portal or in the variables file. The value is aks-<prefix value>.

```
AKSCLUSTERNAME=<AKS cluster name>
AKSRESOURCEGROUP=<AKS RG name>
KV_NAME=<Key vault name>
KV_RESOURCEGROUP=<KV RG name>
```

## Enable aks-preview Azure CLI extension and add AKS-AzureKeyVaultSecretsProvider feature

You also need the *aks-preview* Azure CLI extension version 0.5.9 or later. If you don't already, enter the following in your command line

```bash
# Install the aks-preview extension
az extension add --name aks-preview

# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview
```

You also need to register the AKS-AzureKeyVaultSecretsProvider preview feature in your subscription. Check to see if it has already been enabled

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
Update the permissions on the Key Vault to allow access from the newly created identity. The object-type can be certificate, key or secret. In this case, it should be all 3. Run the command below 3 times, one for each of the options.


```bash
az keyvault set-policy -n $KV_NAME -g $KV_RESOURCEGROUP --<object type>-permissions get --spn <client-id>
```

## Grant access from hub network to private link created for keyvault

For the jumpbox you just created in the hub network to have access to Key vault's private link you need to add the network to the access. To do this,

1. Find the Private DNS zone created for keyvault. This should be in the landing zone resource group (escs-lz01-rg for example)

   ![Location of private link for keyvault](../media/keyvault-privatelink-location.png)

2. Click on **Virtual network links** in the left blade under **Settings**
3. Click on **+ Add** in the in the top left of the next screen
4. enter a name for the link eg *hub_to_kv*
5. Select the hub virtual network for the **Virtual network** field
6. Click on **OK** at the bottom

> :warning: Stop here if you are deploying the blue-green scenario and return to the next step there. Do not deploy the basic workload in the link below.

:arrow_forward: [Deploy a Basic Workload](./08-workload.md)
