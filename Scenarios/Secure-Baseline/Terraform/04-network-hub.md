# Create the Hub Network

The following will be created:
* Resource Group for Hub Neworking (hub-networking.tf)
* Hub Network (hub-networking.tf)
* Azure Firewall (firewall.tf)
* Azure Bastion Host (hub-networking.tf)
* Resource Group for Dev Jumpbox (dev-setup.tf)
* Virtual Machine (dev-setup.tf)

Navigate to "/Scenarios/Secure-Baseline/Terraform/04-Network-Hub" folder
```
cd /Scenarios/Secure-Baseline/Terraform/04-Network-Hub
```

In the "provider.tf" file update the backend settings to reflect the storage account created for Terraform state management.  Do not change the "key" name, as it's referenced later in the deployment files. 

In the "variables.tf" file, update the defaults to reflect the region, tags and prefix you'd like to use throughout the rest of the deployment.  There are a group of "sensitive" variables for the username and password of the jumpbox.  It is not recommended that these variables be commited to code in a public repo, you should instead create a separate terraform.tfvars file (not committed via gitignore) to pass those values in at deployment time. (A sample terraform.tfvars file is included.)

Once the files are updated, deploy using Terraform Init, Plan and Apply. 