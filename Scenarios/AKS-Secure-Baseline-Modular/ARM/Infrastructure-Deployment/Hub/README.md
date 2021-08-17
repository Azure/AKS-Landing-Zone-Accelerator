## ARM templates in Hub folder

This folder contains the ARM templates for deploying the below Azure resources:
* Log Analytics Workspace
* Virtual Network (Hub)
* Azure Firewall
* Azure Bastion Host

>*In the Hub-Spoke topology, all Azure resources which are shared by spoke VNETs will be deployed in Hub VNET. Eg: Firewall, Bastion.. All Spoke VNETs will be connected to the Hub VNET using VNET peering.*
---
### How to deploy the templates
>Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 

```json
az login --tenant <tenant id>
resourcegroup=aks-eslz-arm
az group create --location eastus ----name $resourcegroup
```
#### The templates should be deployed in the below order:

>Ensure that the parameter files of the templates are customized as per your naming standard & browse yourself to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Hub"
* Deploy **Log Analytics Workspace**
```json
az deployment group create --name LogAnalytics --resource-group $resourcegroup --template-file Templates/aks-eslz-la.template.json     --parameters Parameters/aks-eslz-la.parameters.json
```
* Deploy Hub **Virtual Network**
```json
az deployment group create --name Hub --resource-group $resourcegroup --template-file Templates/aks-eslz-hub.template.json   --parameters Parameters/aks-eslz-hub.parameters.json
```
* Deploy **Azure Firewall**
```json
az deployment group create --name Firewall --resource-group $resourcegroup --template-file Templates/aks-eslz-firewall.template.json   --parameters Parameters/aks-eslz-firewall.parameters.json
```
* Deploy **Azure Bastion Host**
```json
az deployment group create --name Bastion --resource-group $resourcegroup --template-file Templates/aks-eslz-bastion.template.json   --parameters Parameters/aks-eslz-bastion.parameters.json
```
