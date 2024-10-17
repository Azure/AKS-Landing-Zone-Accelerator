# Create the Landing Zone Network

The following will be created:

* Resource Group for Landing Zone Networking
* Spoke Virtual Network and Subnets
* Peering of Hub and Spoke Networks
* Private DNS Zones
* Application Gateway
* NSGs for AKS subnet and Application Gateway subnet

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster-AVM/Terraform/" folder

```bash
cd ./04-Network-LZ
```

Review "input.tf" and update the variable values as required. Please note to verify the Azure Firewall Private IP from the previous deployment in step 03. Once the files are updated, deploy using terraform cli.

# [CLI](#tab/CLI)

```terracli
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan -auto-approve
```

:arrow_forward: [Creation of Supporting Components for AKS](./05-aks-supporting.md)
