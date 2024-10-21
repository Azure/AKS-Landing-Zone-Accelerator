# Deploy this scenario using the AKS AVM

This scenario will be deployed using Azure Verified Modules (AVM). AVM is an initiative to consolidate and set the standards for what a good Infrastructure-as-Code module looks like.

Modules will then align to these standards, across languages (Bicep, Terraform etc.) and will then be classified as AVMs and available from their respective language specific registries. These AVMs are fully supported by Microsoft and customers can use them in their production Terraform Code. For more information about AVM, check out the [AVM website](https://azure.github.io/Azure-Verified-Modules/).

# Create the Hub Network

If you haven't yet, clone the repo and cd to the appropriate folder

```bash
git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator
cd ./Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/02-EID
```

The following will be created:

* Resource Group for Hub Networking
* Hub VNET
* Azure Firewall
* Azure Bastion Host

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/" folder

```bash
cd ./03-Network-Hub
```

Review the "input.tf" file and update the variable values if required according to your needs. Pay attentions to VNET address prefixes and subnets so it doesn't overlap Spoke VNET in further steps. Also, please pay attention to update Subnet prefix for AKS cluster in Spoke VNET in the further steps to be planned and update in this file.

Once the files are updated, deploy using terraform cli.

# [CLI](#tab/CLI)

```terracli
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan -auto-approve
```

:arrow_forward: [Creation of Spoke Network & its respective Components](./04-network-lz.md)
