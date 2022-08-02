# Create resources that support AKS

The following will be created:
* Azure Container Registry (supporting-infra.tf)
* Azure Key Vault (supporting-infra.tf)
* Private Link Endpoints for ACR and Key Vault
* Public DNS Zone (supporting-infra.tf)

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/06-AKS-supporting" folder
```
cd ../06-AKS-supporting
```

This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed in the .tfvars sample file.  This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

Once again, A sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

### Add the Access key variable to terraform.tfvars

1. Open the *terraform.tfvars.sample* file and add the access key as the value of the access_key variable.  Update the other storage related variables. 
1. Rename the file to *terraform.tfvars*

## Deploy the Supporting Services 

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

```bash
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
```

```
terraform plan
```

```
terraform apply
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.

:arrow_forward: [Creation of AKS & enabling Addons](./07-aks-cluster.md)
