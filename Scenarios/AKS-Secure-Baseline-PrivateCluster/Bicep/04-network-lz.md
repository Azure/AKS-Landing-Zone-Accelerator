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

Review "main.bicepparam" and update the values as required. Please note to verify the Azure Firewall Private IP from the previous deployment in step 03. Once the files are updated, deploy using az cli or Az PowerShell

# [CLI](#tab/CLI)

```azurecli
az deployment sub create -n "AKS-LZA-Spoke-AKS" -l $REGION -f main.bicep -p main.bicepparam
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile .\04-Network-LZ\main.bicep -TemplateParameterFile .\04-Network-LZ\main.bicepparam -Location $REGION -Name AKS-LZA-Spoke-AKS
```

:arrow_forward: [Creation of Supporting Components for AKS](./05-aks-supporting.md)
