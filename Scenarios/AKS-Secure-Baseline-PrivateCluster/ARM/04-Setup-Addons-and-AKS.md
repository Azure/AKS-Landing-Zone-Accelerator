## Setup AKS and its Addons

This folder contains the ARM templates for deploying AKS resource

### How to deploy the templates
>Before executing this template, ensure that you are connected to your Azure subscription using AZ CLI or PowerShell and a Resource Group has been created for these new deployments. 
> We also need to ensure that all resources are configured in Hub & Deployment

```bash
# login if you haven't already
# az login --tenant <tenant id>
AKS_RESOURCEGROUP=aks-eslz-arm
```


Navigate to "Enterprise-Scale-for-AKSmain/Scenarios/AKS-Secure-Baseline-Modular/ARM/Infrastructure-Deployment/Supporting-components/Parameters" folder
```bash
cd ../../../AKS-Deployment
```

<br/>

* Deploy **AKS**
```json
az deployment group create --name AKS_Deployment --resource-group $AKS_RESOURCEGROUP --template-file aks-eslz-aks.template.json --parameters @aks-eslz-aks.parameters.json
```
## Enabling Addons
 > Pod Identity

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
az aks get-credentials --resource-group $AKS_RESOURCEGROUP --name aks-eslz1
```

```json
az aks update -g $AKS_RESOURCEGROUP -n aks-eslz1 --enable-pod-identity
```
> Application Gateway Addon
```json
az aks enable-addons -n aks-eslz1 -g $AKS_RESOURCEGROUP -a ingress-appgw --appgw-id $(az network application-gateway show -n app_gateway -g $AKS_RESOURCEGROUP -o tsv --query "id")
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
 az aks enable-addons --addons azure-keyvault-secrets-provider --name aks-eslz1 --resource-group $AKS_RESOURCEGROUP
```
