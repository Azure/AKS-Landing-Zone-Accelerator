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

Review "parameters-main.json" and update the values as required. Once the files are updated, deploy using az cli or Az PowerShell

# [CLI](#tab/CLI)

```azurecli
az deployment sub create -n "ESLZ-AKS-Supporting" -l "CentralUS" -f main.bicep -p parameters-main.json
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile .\05-AKS-supporting\main.bicep -TemplateParameterFile .\05-AKS-supporting\parameters-main.json -Location "CentralUS" -Name ESLZ-AKS-Supporting
```

:arrow_forward: [Creation of AKS & enabling Addons](./06-aks-cluster.md)