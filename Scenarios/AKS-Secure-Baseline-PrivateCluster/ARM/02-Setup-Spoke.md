## Creat the Spoke Network

In this section, we will be creating the spoke network and supporting resources:
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

```bash
# login if you haven't already
# az login --tenant <tenant id>
SPOKE_RESOURCE_GROUP=aks-eslz-arm
az group create --location eastus --name $SPOKE_RESOURCE_GROUP
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files of the templates are customized as per your naming standard

Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Spoke/Parameters" folder
```bash
cd ../../Spoke/Parameters
```
* Deploy Spoke **Virtual Network**
```bash
az deployment group create --name Spoke --resource-group $SPOKE_RESOURCE_GROUP --template-file ../Templates/aks-eslz-spoke.template.json --parameters @aks-eslz-spoke.parameters.json
```
* Create **VNET peering** with Hub VNET
```bash
az deployment group create --name Peering --resource-group $SPOKE_RESOURCE_GROUP --template-file ../Templates/aks-eslz-vnet-peering.template.json
```
* Create a **Public IP address** for application Gateway.
```bash
az deployment group create --name PublicIP --resource-group $SPOKE_RESOURCE_GROUP --template-file ../Templates/aks-eslz-publicip.template.json --parameters @aks-eslz-publicip.parameters.json
```
* Deploy **Application Gateway** with WAFv2
```bash
az deployment group create --name AppGateway --resource-group $SPOKE_RESOURCE_GROUP --template-file ../Templates/aks-eslz-applicationgateway.template.json --parameters @aks-eslz-applicationgateway.parameters.json
```

### Next step

:arrow_forward: [Creation of Shared-components](./03-Setup-supporting-components.md)
