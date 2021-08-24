# Create resources for the AKS Cluster

The following will be created:
* Resource Group for AKS
* AKS Cluster
* Log Analytics Workspace
* Managed Identity for AKS Control Plane
* Managed Identity for Application Gateway Ingress Controller
* AKS Pod Identity Assignments - OPTIONAL

Navigate to "/Scenarios/Secure-Baseline/Terraform/07-AKS-cluster" folder
```
cd /Scenarios/Secure-Baseline/Terraform/07-AKS-cluster
```

In the "provider.tf" file update the backend settings to reflect the storage account created for Terraform state management.  Do not change the "key" name, as it's referenced later in the deployment files. 

In the "variables.tf" file, update the defaults to reflect prefix you'd like to use.  
This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed.  Once again, this deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

## The Key Vault Add-On
The AKS Key Vault Add-On is not currently supported for deployment with Terraform. Configure that separtely on the cluster after it is deployed. 
```
az aks enable-addons --addons azure-keyvault-secrets-provider --name myAKSCluster --resource-group myResourceGroup
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

Update the permissions on the Key Vault to allow access to the newly created identity.
```
az keyvault set-policy -n <keyvault-name> --<object-type>-permissions get --spn <client-id>
```

:arrow_forward: [Deploy a Basic Workload](./08-workload.md)