# Deployment of ARM templates using PowerShell
## Steps

> *Ensure that you have deployed all the Azure resources in the hub folder before proceeding with the below steps.*

* Connect to Azure subscription
```
Login-azAccount -tenant <tenant name>
```
* Deploy Spoke **Virtual Networks**
```
New-AzResourceGroupDeployment -Name Spoke -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-spoke.parameters.json -TemplateFile .\Hub\templates\aks-eslz-spoke.template.json -Verbose
```
* Create **VNET peering** with Hub VNET
```
New-AzResourceGroupDeployment -Name Peering -ResourceGroupName $resourcegroup -TemplateFile .\Hub\templates\aks-eslz-vnet-peering.template.json -Verbose
```
* Deploy **Azure KeyVault** with Private Endpoint
```
New-AzResourceGroupDeployment -Name KeyVault -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-keyvault.parameters.json -TemplateFile .\Hub\templates\aks-eslz-keyvault.template.json -Verbose
```
* Deploy **Azure Container Registry (ACR)** with Private Endpoint
```
New-AzResourceGroupDeployment -Name ACR -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-containerregistry.parameters.json -TemplateFile .\Hub\templates\aks-eslz-containerregistry.template.json -Verbose
```
* Create a **Public IP address** for application Gateway.
```
New-AzResourceGroupDeployment -Name PublicIP -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-publicip.parameters.json -TemplateFile .\Hub\templates\aks-eslz-publicip.template.json -Verbose
```
* Deploy **Application Gateway** with WAFv2
```
New-AzResourceGroupDeployment -Name ApplicationGateway -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-applicationgateway.parameters.json -TemplateFile .\Hub\templates\aks-eslz-applicationgateway.template.json -Verbose
```
