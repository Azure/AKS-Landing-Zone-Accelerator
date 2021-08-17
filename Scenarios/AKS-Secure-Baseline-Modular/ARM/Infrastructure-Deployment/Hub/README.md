## ARM templates in Hub folder

This folder contains the ARM templates for deploying the below Azure resources:
* Log Analytics Workspace
* Virtual Network (Hub)
* Azure Firewall
* Azure Bastion Host

>In the Hub-Spoke topology, all Azure resources which are shared by spoke VNETs will be deployed in Hub VNET. Eg: Firewall, Bastion.. All Spoke VNETs will be connected to the Hub VNET using VNET peering.
---
### How to deploy the templates
>Before executing these templates, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 

```json
az login --tenant <tenant id>
resourcegroup=aks-eslz-arm
az group create --location eastus --name $resourcegroup
```
#### The templates should be deployed in the below order:

* Deploy Log Analytics Workspace
```json
az deployment group create \
	--name LogAnalytics \
	--resource-group $resourcegroup \
	--template-file hub\templates\aks-eslz-la.json \
  --parameters @aks-eslz-la.parameters.json
```
* Deploy Hub VNET
```json
az deployment group create \
	--name Hub \
	--resource-group $resourcegroup \
	--template-file hub\templates\aks-eslz-hub.json \
  --parameters @aks-eslz-hub.parameters.json
```
* Deploy Azure Firewall
```json
az deployment group create \
	--name Firewall \
	--resource-group $resourcegroup \
	--template-file hub\templates\aks-eslz-firewall.json \
  --parameters @aks-eslz-firewall.parameters.json
```
* Deploy Azure Bastion Host
```json
az deployment group create \
	--name Bastion \
	--resource-group $resourcegroup \
	--template-file hub\templates\aks-eslz-bastion.json \
  --parameters @aks-eslz-bastion.parameters.json
```
