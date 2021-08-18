# Deployment of ARM templates using PowerShell
## Steps
* Connect to Azure subscription
```
Login-azAccount -tenant <tenant name>
```
* Create a new Azure resource group for deploying the resources
```
$resourcegroup = <resource group name>
$location = <location name>
New-AzResourceGroup -Name $resourcegroup -Location $location
```
* Create **Log Analytics**
```
New-AzResourceGroupDeployment -Name LA -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-la.parameters.json -TemplateFile .\Hub\templates\aks-eslz-la.template.json -Verbose
```
* Create Hub **Virtual Network**
```
New-AzResourceGroupDeployment -Name Hub -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-hub.parameters.json -TemplateFile .\Hub\templates\aks-eslz-hub.template.json -Verbose
```
* Create **Azure Firewall**
```
New-AzResourceGroupDeployment -Name Firewall -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-firewall.parameters.json -TemplateFile .\Hub\templates\aks-eslz-firewall.template.json -Verbose
```
* Create **Azure Bastion Host**
```
New-AzResourceGroupDeployment -Name Bastion -ResourceGroupName $resourcegroup -TemplateParameterFile .\Hub\Parameters\aks-eslz-bastion.parameters.json -TemplateFile .\Hub\templates\aks-eslz-bastion.template.json -Verbose
```
