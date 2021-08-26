# Create resources for the AKS Cluster

The following will be created:
* Resource Group for AKS
* AKS Cluster
* Log Analytics Workspace
* Managed Identity for AKS Control Plane
* Managed Identity for Application Gateway Ingress Controller
* AKS Pod Identity Assignments - OPTIONAL

Navigate to "/Scenarios/Secure-Baseline/Terraform/07-AKS-cluster" folder
```bash
cd ../07-AKS-cluster
```

In the "provider.tf" file update the backend settings to reflect the storage account created for Terraform state management.  Do not change the "key" name, as it's referenced later in the deployment files. 

In the "variables.tf" file, update the defaults to reflect prefix you'd like to use.  
This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed.  Once again, this deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

```bash
terraform init
```

```bash
terraform plan
```

```bash
terraform apply
```



## The Key Vault Add-On
The AKS Key Vault Add-On is not currently supported for deployment with Terraform. Configure that separtely on the cluster after it is deployed. 

We start by creating some environment variables. The AKS cluster name can be found in the portal or in the variables file. The value is aks-<prefix value> in this case it is aks-escs for example. The resource group is 

```
AKSCLUSTERNAME=aks-escs
AKSRESOURCEGROUP=escs-lz01-rg-aks
```



## Enable aks-preview Azure CLI extenstion and add AKS-AzureKeyVaultSecretsProvider preview feature

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

It takes a few minutes for the status to show *Registered*. Verify the registration status by using the [az feature list](https://docs.microsoft.com/en-us/cli/azure/feature#az_feature_list) command:

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

When ready, refresh the registration of the *Microsoft.ContainerService* resource provider by using the [az provider register](https://docs.microsoft.com/en-us/cli/azure/provider#az_provider_register) command:

```bash
az provider register --namespace Microsoft.ContainerService
```

```
az aks enable-addons --addons azure-keyvault-secrets-provider --name $AKSCLUSTERNAME --resource-group $AKSRESOURCEGROUP


```
When completed, take note of the client-id created for the add-on:

...,
 "addonProfiles": {
    "azureKeyvaultSecretsProvider": {
      ...,
      "identity": {
        "clientId": "<client-id>",
        ...
      }
    }

Update the permissions on the Key Vault to allow access from the newly created identity. The object type can be key or secret. In this case it should be secret.
```
az keyvault set-policy -n <keyvault-name> --<object-type>-permissions get --spn <client-id>
```



:arrow_forward: [Deploy a Basic Workload](./08-workload.md)