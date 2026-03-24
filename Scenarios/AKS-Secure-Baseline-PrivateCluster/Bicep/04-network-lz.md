# Create the Landing Zone Network

The following will be created:

* Resource Group for Landing Zone Networking
* Spoke Virtual Network and Subnets
* Peering of Hub and Spoke Networks
* Private DNS Zones
* Application Gateway for Containers (AGC) traffic controller
* NSG for AKS subnet

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/04-Network-LZ" folder

```bash
cd ../04-Network-LZ
```

Review "main.bicepparam" and update the values as required. Please note to verify the Azure Firewall Private IP from the previous deployment in step 03. Once the files are updated, deploy using [deployment stacks](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deployment-stacks).

# [CLI](#tab/CLI)

```azurecli
az stack sub create \
  --name "AKS-LZA-SPOKE" \
  --location $REGION \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --action-on-unmanage detachAll \
  --deny-settings-mode none
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeploymentStack `
  -Name "AKS-LZA-SPOKE" `
  -Location $REGION `
  -TemplateFile .\04-Network-LZ\main.bicep `
  -TemplateParameterFile .\04-Network-LZ\main.bicepparam `
  -ActionOnUnmanage DetachAll `
  -DenySettingsMode None
```

:arrow_forward: [Creation of Supporting Components for AKS](./05-aks-supporting.md)
