# Create the Hub Network

If you haven't yet, clone the repo and cd to the appropriate folder

```bash
git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator
cd ./Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/02-AAD
```

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

Note: "parameters-deploy-vm.json" file contains the username and password for the virtual machine. These can be changed in the parameters file for the vm, however these are the default values:

Username: azureuser
Password: Password123

Once the files are updated, deploy using az cli or Az PowerShell.

# [CLI](#tab/CLI)

```azurecli
REGION=CentralUS
az deployment sub create -n "ESLZ-HUB-AKS" -l $REGION -f main.bicep -p parameters-main.json
az deployment sub create -n "ESLZ-AKS-HUB-UDR" -l $REGION -f updateUDR.bicep -p parameters-updateUDR.json
az deployment sub create -n "ESLZ-HUB-VM" -l $REGION -f deploy-vm.bicep -p parameters-deploy-vm.json
```

# [PowerShell](#tab/PowerShell)

```azurepowershell
$REGION="CentralUS"
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\main.bicep -TemplateParameterFile .\03-Network-Hub\parameters-main.json -Location $REGION -Name ESLZ-HUB-AKS
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\updateUDR.bicep -TemplateParameterFile .\03-Network-Hub\parameters-updateUDR.json -Location $REGION -Name ESLZ-AKS-HUB-UDR
New-AzSubscriptionDeployment -TemplateFile .\03-Network-Hub\deploy-vm.bicep -TemplateParameterFile .\03-Network-Hub\parameters-deploy-vm.json -Location $REGION -Name ESLZ-HUB-VM
```

:arrow_forward: [Creation of Spoke Network & its respective Components](./04-network-lz.md)
