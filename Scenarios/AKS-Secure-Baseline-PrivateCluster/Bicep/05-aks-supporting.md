# Create resources that support AKS

The following will be created:

* Azure Container Registry
* Azure Key Vault
* Private Link Endpoints for ACR and Key Vault
* Related DNS settings for private endpoints
* A managed identity

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/05-AKS-supporting" folder

```bash
cd ../05-AKS-supporting
```

Review "main.bicepparam" and update the values as required. Once the files are updated, deploy using [deployment stacks](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks).

# [CLI](#tab/CLI)

```azurecli
az stack sub create \
  --name "AKS-LZA-SUPPORTING" \
  --location $REGION \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeploymentStack `
  -Name "AKS-LZA-SUPPORTING" `
  -Location $REGION `
  -TemplateFile .\05-AKS-supporting\main.bicep `
  -TemplateParameterFile .\05-AKS-supporting\main.bicepparam `
  -ActionOnUnmanage DetachAll `
  -DenySettingsMode None
```

:arrow_forward: [Creation of AKS & enabling Addons](./06-aks-cluster.md)
