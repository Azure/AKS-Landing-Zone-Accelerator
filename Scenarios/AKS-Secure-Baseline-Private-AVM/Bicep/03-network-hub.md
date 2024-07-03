# Deploy this scenario using the AKS AVM
This scenario will be deployed using Azure Verified Modules (AVM). AVM is an initiative to consolidate and set the standards for what a good Infrastructure-as-Code module looks like.

Modules will then align to these standards, across languages (Bicep, Terraform etc.) and will then be classified as AVMs and available from their respective language specific registries. These AVMs are fully supported by Microsoft and customers can use them in their production Bicep Code. For more information about AVM, check out the [AVM website](https://azure.github.io/Azure-Verified-Modules/).

# Create the Hub Network

If you haven't yet, go back to 02-EID and complete the steps.

The following will be created:

* Resource Group for Hub Networking
* Hub VNET
* Azure Firewall
* Azure Bastion Host
* Virtual Machine

Navigate to "/Scenarios/AKS-Secure-Baseline-Private-AVM/Bicep/03-Network-Hub" folder

```bash
cd ../03-Network-Hub
```

Review the "parameters-main.json" file and update the parameter values if required according to your needs. Pay attentions to VNET address prefixes and subnets so it doesn't overlap Spoke VNET in further steps. Also, please pay attention to update Subnet prefix for AKS cluster in Spoke VNET in the further steps to be planned and update in this file.

Once the files are updated, deploy using az cli or Az PowerShell.

# [CLI](#tab/CLI)

```azurecli
REGION=CentralUS
az deployment sub create -n "AKS-LZA-HUB-AKS" -l $REGION -f main.bicep -p parameters-main.json
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
$REGION="CentralUS"
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\main.bicep -TemplateParameterFile .\03-Network-Hub\parameters-main.json -Location $REGION -Name AKS-LZA-HUB-AKS
```

:arrow_forward: [Creation of Spoke Network & its respective Components](./04-network-lz.md)
