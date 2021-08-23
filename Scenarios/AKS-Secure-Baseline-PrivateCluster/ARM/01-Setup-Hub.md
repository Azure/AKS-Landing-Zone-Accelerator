## Create the Hub Network

This folder contains the ARM templates for deploying the below Azure resources:
* Log Analytics Workspace
* Virtual Network (Hub)
* Azure Firewall
* Azure Bastion Host
* Virtual Machine

>*In the Hub-Spoke topology, all Azure resources which are shared by spoke VNETs will be deployed in Hub VNET. Eg: Firewall, Bastion.. All Spoke VNETs will be connected to the Hub VNET using VNET peering.*
---
### How to deploy the templates
>Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 

```bash
az login --tenant <tenant id>
HUB_RESOURCEGROUP=aks-eslz-arm-hub
az group create --location eastus --name $HUB_RESOURCEGROUP
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files in the Templates folders are customized as per your naming standard. These files can be found in the folders called **Templates** within the various directors in this scenario.

Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Hub/Parameters" folder
```bash
cd Scenarios/AKS-Secure-Baseline-PrivateCluster/ARM/Infrastructure-Deployment/Hub/Parameters
```
## Deploy the Hub
* Deploy **Log Analytics Workspace**
> [!NOTE]
> You can check the various arm template files to see the resources that would be deployed by the following deployment groups by checking out the files in the appropriate folder shown in the deployment steps below.
```bash
az deployment group create --name LogAnalytics --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-la.template.json --parameters @aks-eslz-la.parameters.json
```
* Deploy Hub **Virtual Network**
```bash
az deployment group create --name Hub --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-hub.template.json --parameters @aks-eslz-hub.parameters.json
```
* Deploy **Azure Firewall**
```bash
az deployment group create --name Firewall --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-firewall.template.json --parameters @aks-eslz-firewall.parameters.json
```
* Deploy **Azure Bastion Host**
```bash
az deployment group create --name Bastion --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-bastion.template.json --parameters @aks-eslz-bastion.parameters.json
```

**Optional Components** : For management of resources we're providing the sample for a VM creation

* Update <ins>Network Policies for AzureManagementSubnet</ins>
```bash
az network vnet subnet update --disable-private-endpoint-network-policies true --name AzureManagementSubnet --resource-group $HUB_RESOURCEGROUP --vnet-name vnet_hub_arm 
```

* Deploy **Virtual Machine**
```bash
az deployment group create --name Bastion --resource-group $HUB_RESOURCEGROUP --template-file ../Templates/aks-eslz-virtualmachine.template.json --parameters @aks-eslz-virtualmachine.parameters.json
```

### Next step

:arrow_forward: [Creation of Spoke Network & its respective Components](./02-Setup-Spoke.md)
