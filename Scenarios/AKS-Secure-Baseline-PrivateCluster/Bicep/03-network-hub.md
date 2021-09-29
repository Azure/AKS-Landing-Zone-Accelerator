# Create the Hub Network

The following will be created:

* Resource Group for Hub Networking
* Hub VNET
* Azure Firewall
* Azure Bastion Host
* Virtual Machine

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/03-Network-Hub" folder

```bash
cd ../03-Network-Hub
```

Review the "parameters-main.json" file and update the parameter values if required according to your needs. Pay attentions to VNET address prefixes and subnets so it doesn't overlap Spoke VNET in further steps. Also, please pay attention to update Subnet prefix for AKS cluster in Spoke VNET in the further steps to be planned and update in this file.

Review "parameters-updateUDR.json" and "parameters-deploy-vm.json" to update any parameters previously updated in "parameters-main.json".

Note: "parameters-deploy-vm.json" file contains public key value with a default value. We recommend to use your own ssh key pair for troubleshooting the cluster through the VM.

Once the files are updated, deploy using az cli or Az PowerShell.

# [CLI](#tab/CLI)

```azurecli
az deployment sub create -n "ESLZ-HUB-AKS" -l "CentralUS" -f main.bicep -p parameters-main.json
az deployment sub create -n "ESLZ-AKS-HUB-UDR" -l "CentralUS" -f updateUDR.bicep -p parameters-updateUDR.json
az deployment sub create -n "ESLZ-HUB-VM" -l "CentralUS" -f deploy-vm.bicep -p parameters-deploy-vm.json
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\main.bicep -TemplateParameterFile .\03-Network-Hub\parameters-main.json -Location "CentralUS" -Name ESLZ-HUB-AKS
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\updateUDR.bicep -TemplateParameterFile .\03-Network-Hub\parameters-updateUDR.json -Location "CentralUS" -Name ESLZ-AKS-HUB-UDR
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\deploy-vm.bicep -TemplateParameterFile .\03-Network-Hub\parameters-deploy-vm.json -Location "CentralUS" -Name ESLZ-HUB-VM
```

:arrow_forward: [Creation of Spoke Network & its respective Components](./04-network-lz.md)