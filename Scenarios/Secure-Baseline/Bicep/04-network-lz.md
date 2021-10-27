# Create the Landing Zone Network

The following will be created:

* Resource Group for Landing Zone Networking
* Spoke Virtual Network and Subnets
* Peering of Hub and Spoke Networks
* Private DNS Zones
* Application Gateway
* NSGs for AKS subnet and Application Gateway subnet

Navigate to "/Scenarios/Secure-Baseline/Bicep/04-Network-LZ" folder

```bash
cd ../04-Network-LZ
```

Review "parameters-main.json" and update the values as required. Please note to verify the Azure Firewall Private IP (dhcp options in parameters-main.json) from the previous deployment in step 03. Once the files are updated, deploy using az cli or Az PowerShell

# [CLI](#tab/CLI)

```azurecli
az deployment sub create -n "ESLZ-Spoke-AKS" -l "CentralUS" -f main.bicep -p parameters-main.json

# Wait until App Gateway gets deployed. It takes a few mins to complete, at least 10 min.

az deployment sub create -n "ESLZ-AKS-SPOKE-UDRNSG" -l "CentralUS" -f updateUDR-NSG.bicep -p parameters-updateUDR-NSG.json
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile .\04-Network-LZ\main.bicep -TemplateParameterFile .\04-Network-LZ\parameters-main.json -Location "CentralUS" -Name ESLZ-Spoke-AKS

# Wait until App Gateway gets deployed. It takes a few mins to complete, at least 10 min.

New-AzSubscriptionDeployment -TemplateFile .\04-Network-LZ\updateUDR-NSG.bicep -TemplateParameterFile .\04-Network-LZ\parameters-updateUDR-NSG.json -Location "CentralUS" -Name ESLZ-AKS-SPOKE-UDRNSG
```

:arrow_forward: [Creation of Supporting Components for AKS](./05-aks-supporting.md)