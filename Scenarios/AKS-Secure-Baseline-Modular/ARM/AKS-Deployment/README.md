## ARM templates in Hub folder

This folder contains the ARM templates for deploying AKS resource

### How to deploy the templates
>Before executing this template, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 
> We also need to ensure that all resources are configured in Hub & Deployment
```json
az login --tenant <tenant id>
resourcegroup=aks-eslz-arm
```


>Ensure that the parameter files of the templates are customized as per your naming standard & browse yourself to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Hub"

<br/>

>Change your current working directory to 'Parameters' folder 

> Browse yourself to <ins>Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/AKS-Deployment</ins>
* Deploy **AKS**
```json
az deployment group create --name AKS_Deployment --resource-group $resourcegroup --template-file aks-eslz-aks.template.json --parameters @aks-eslz-aks.parameters.json
```
