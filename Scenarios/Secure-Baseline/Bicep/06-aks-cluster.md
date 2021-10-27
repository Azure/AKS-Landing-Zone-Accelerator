# Create resources for the AKS Cluster

The following will be created:

* AKS Cluster with KeyVault (preview), AGIC and monitoring addons
* Log Analytics Workspace
* ACR Access to the AKS Cluster
* Updates to KeyVault access policy with AKS keyvault addon

Navigate to "/Scenarios/Secure-Baseline/Bicep/06-AKS-cluster" folder

```bash
cd ../06-AKS-cluster
```

To create an AKS cluster that can use the Secrets Store CSI Driver, you must enable the AKS-AzureKeyVaultSecretsProvider feature flag on your subscription. Register the AKS-AzureKeyVaultSecretsProvider feature flag by using the az feature register command, as shown below

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

if not enter the command below to enable it

```bash
az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
```

It takes a few minutes for the status to show *Registered*. Verify the registration status by using the [az feature list](https://docs.microsoft.com/en-us/cli/azure/feature#az_feature_list) command:

```bash
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-AzureKeyVaultSecretsProvider')].{Name:name,State:properties.state}"
```

When ready, refresh the registration of the *Microsoft.ContainerService* resource provider by using the [az provider register](https://docs.microsoft.com/en-us/cli/azure/provider#az_provider_register) command:

```bash
az provider register --namespace Microsoft.ContainerService
```

Review "parameters-main.json" file and update the values as required. Please make sure to update the AAD Group IDs with ones created in Step 02 in the parameters file. Once the files are updated, deploy using az cli or Az PowerShell

# [CLI](#tab/CLI)

```azurecli
acrName=$(az deployment sub show -n "ESLZ-AKS-Supporting" --query properties.outputs.acrName.value -o tsv)
keyVaultName=$(az deployment sub show -n "ESLZ-AKS-Supporting" --query properties.outputs.keyvaultName.value -o tsv)

az deployment sub create -n "ESLZ-AKS-CLUSTER" -l "CentralUS" -f main.bicep -p parameters-main.json -p acrName=$acrName -p keyvaultName=$keyVaultName
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile .\06-AKS-cluster\main.bicep -TemplateParameterFile .\06-AKS-cluster\parameters-main.json -Location "CentralUS" -Name ESLZ-AKS-CLUSTER
```

:arrow_forward: [Deploy a Basic Workload](./07-workload.md)