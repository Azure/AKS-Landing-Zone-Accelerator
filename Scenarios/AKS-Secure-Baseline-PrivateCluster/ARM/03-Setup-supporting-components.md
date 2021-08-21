## ARM templates in Shared-Components folder

This folder contains the ARM templates for deploying the below Azure resources:
* Azure Key Vault
* Azure Container Registry (ACR)

Before deploying the Azure resources from this folder, please ensure that all the resources are deployed as mentioned in the [Hub & Spoke directory](https://github.com/Azure/Enterprise-Scale-for-AKS/tree/main/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment).
For deploying an AKS cluster, the Spoke VNET should be having basic supporting infra components like Azure Key Vault, Azure Container Registry and Azure Application Gateway.

>*For secure communication between Azure Key Vault and ACR, private endpoints will be used.*
>
>*For better flexibility, Application Gateway has been deployed separetely and not as an AKS add-on. This helps customers to make use of their existing Application Gateway for AKS.*
---
### How to deploy the templates
Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created to hold these new deployments.

```bash
# login if you haven't already
# az login --tenant <tenant id>
SUPPORTING_RESOURCEGROUP=aks-eslz-arm
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files of the templates are customized as per your naming standard

Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Supporting-components/Parameters" folder
```bash
cd ../../Supporting-components/Parameters
```
* Deploy **Azure KeyVault** with Private Endpoint.
```bash
az deployment group create --name KeyVault --resource-group $SUPPORTING_RESOURCEGROUP --template-file ../Templates/aks-eslz-keyvault.template.json --parameters @aks-eslz-keyvault.parameters.json
```
* Deploy **Azure Container Registry (ACR)** with Private Endpoint
```bash
az deployment group create --name ACR --resource-group $SUPPORTING_RESOURCEGROUP --template-file ../Templates/aks-eslz-containerregistry.template.json --parameters @aks-eslz-containerregistry.parameters.json
```

:arrow_forward: [Generate your client-facing TLS certificate](./04-Setup-Addons-and-AKS.md)