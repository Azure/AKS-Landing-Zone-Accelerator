## ARM templates in Spoke folder

This folder contains the ARM templates for deploying the below Azure resources:
* Virtual Network (Spoke)
* Azure Application Gateway
* VNET Peering
* Public IP Allocation for Appgateway

<br/>

Before deploying the Azure resources from this folder, please ensure that all the resources are deployed as mentioned in the [Hub directory](https://github.com/Azure/Enterprise-Scale-for-AKS/tree/main/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Hub).
For deploying an AKS cluster, the Spoke VNET should be having basic supporting infra components like Azure Key Vault, Azure Container Registry and Azure Application Gateway.

>*For secure communication between Azure Key Vault and ACR, private endpoints will be used.*
>
>*For better flexibility, Application Gateway has been deployed separetely and not as an AKS add-on. This helps customers to make use of their existing Application Gateway for AKS.*
---
### How to deploy the templates
Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created to hold these new deployments.

```json
az login --tenant <tenant id>
resourcegroup=aks-eslz-arm
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files of the templates are customized as per your naming standard
* Deploy Spoke **Virtual Network**
```json
az deployment group create --name Spoke --resource-group $resourcegroup --template-file ../templates/aks-eslz-spoke.template.json --parameters @aks-eslz-spoke.parameters.json
```
* Create **VNET peering** with Hub VNET
```json
az deployment group create --name Peering --resource-group $resourcegroup --template-file ../templates/aks-eslz-vnet-peering.template.json
```
* Create a **Public IP address** for application Gateway.
```json
az deployment group create --name PublicIP --resource-group $resourcegroup --template-file ../templates/aks-eslz-publicip.template.json --parameters @aks-eslz-publicip.parameters.json
```
* Deploy **Application Gateway** with WAFv2
```json
az deployment group create --name AppGateway --resource-group $resourcegroup --template-file ../templates/aks-eslz-applicationgateway.template.json --parameters @aks-eslz-applicationgateway.parameters.json
```
