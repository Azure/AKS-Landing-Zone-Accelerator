# Create resources that support AKS

The following will be created:
* [Azure Container Registry (ACR)](./06-AKS-supporting/supporting-infra.tf)
* [Azure Key Vault](./06-AKS-supporting/supporting-infra.tf)
* Private Link Endpoints for ACR and Key Vault

Navigate to "\Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\06-AKS-supporting" folder
```PowerShell
cd ..\06-AKS-supporting
```

This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed in the .tfvars sample file.  This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

Once again, A sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

### Add the Access key variable to terraform.tfvars

1. Open the *terraform.tfvars.sample* file and add the access key as the value of the access_key variable.  Update the other storage related variables. 
1. Rename the file to *terraform.tfvars* or use the existing terraform.tfvars file.


### Deploy the adjacent cluster resources
Using the same PowerShell session from the previous step, update the state file name that will be used for this part of the deployment.

```PowerShell
$layerNametfstate="aks-sup" # same as state file name provided in provider.tf 
$access_key = "" # TF state file Azure storage account access key
```

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

```PowerShell
terraform init -input=false -backend-config="resource_group_name=$backendResourceGroupName" -backend-config="storage_account_name=$backendStorageAccountName" -backend-config="container_name=$backendContainername" -backend-config="key=$layerNametfstate"
```

```PowerShell
terraform plan -var "storage_account_name=$backendStorageAccountName" -var "container_name=$backendContainername" -var "access_key=$access_key" -out $layerNametfstate
```

```PowerShell
terraform apply --auto-approve $layerNametfstate
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.
If you get an error about list of available provider versions, go with the `-upgrade` flag option to allow selection of new versions.

# Next Step
:arrow_forward: [Creation of AKS & enabling Addons](./07-aks-cluster.md)
