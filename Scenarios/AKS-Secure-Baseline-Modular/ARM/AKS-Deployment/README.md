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
## Enabling Addons
 > Pod Identity
####################################################################################################

>> Pod Identities
```json
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
```
>> Install the aks-preview extension
```json
az extension add --name aks-preview
```

>> Update the extension to make sure you have the latest version installed
```json
az extension update --name aks-preview
```

```json
az aks update -g $resourcegroup -n aks-eslz1 --enable-pod-identity
```

<br/>


---

<br/>

> Application Gateway Addon
```json
az aks enable-addons -n aks-eslz1 -g $resourcegroup -a ingress-appgw --appgw-id $(az network application-gateway show -n app_gateway -g $resourcegroup -o tsv --query "id")
```

> Enable CSI

```json
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
```
>> It takes a few minutes for the status to show Registered. Verify the registration status by using the az feature list command
```json
 az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
 ```
>> When ready, refresh the registration of the Microsoft.ContainerService resource provider by using the az provider register command
```json
 az provider register --namespace Microsoft.ContainerService
```

>> Install the aks-preview extension
```json
 az extension add --name aks-preview
```
>> Update the extension to make sure you have the latest version installed
```json
 az extension update --name aks-preview
```

>> To upgrade an existing AKS cluster with Secrets Store CSI Driver capability, use the az aks enable-addons command with the addon azure-keyvault-secrets-provider
```json
 az aks enable-addons --addons azure-keyvault-secrets-provider --name aks-eslz1 --resource-group $resourcegroup
```