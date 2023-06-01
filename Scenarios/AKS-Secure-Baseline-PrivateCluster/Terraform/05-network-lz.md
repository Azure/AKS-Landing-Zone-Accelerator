# Create the Landing Zone Network

The following will be created:
* [Resource Group for Landing Zone Networking](./05-Network-LZ/lz-networking.tf)
* [Route Table](./05-Network-LZ/lz-networking.tf)
* [Peering of Hub and Spoke Networks](./05-Network-LZ/hub-spoke-peering.tf)
* [Private DNS Zones](./05-Network-LZ/dns-zones.tf)
* [Azure Front Door](./05-Network-LZ/modules/cdn/cdn.tf)
* [Subnet for AKS](./05-Network-LZ/aks-networking.tf)

Navigate to "\Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\05-Network-LZ" folder

```PowerShell
cd ..\05-Network-LZ
```

In the "variables.tf" file, update the defaults to reflect the tags you'd like to use.  
This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed.  

This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

Once again, A sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

To get the access key:

1. Go to Azure portal and find the storage account that was created for Terraform
2. Under **Security + networking** section in the left blade, click on **Access keys**
3. Click on **Show keys** at the top of the resulting page 
4. Copy the string under **Key** from one of the two keys provided
5. Update your the terraform.tfvars.sample file with this as the value for access_key or update the existing terraform.tfvars file. 
6. If using terraform.tfvars.sample then Rename the file to terraform.tfvars

### Deploy the spoke networking and Application Gateway

Using the same PowerShell session from the previous step, update the state file name that will be used for this part of the deployment.

```PowerShell
$layerNametfstate="lz-net" # same as state file name provided in provider.tf 
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
:arrow_forward: [Creation of Supporting Components for AKS](./06-aks-supporting.md)

