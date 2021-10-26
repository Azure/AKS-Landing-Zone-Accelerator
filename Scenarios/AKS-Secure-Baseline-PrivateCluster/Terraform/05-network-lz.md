# Create the Landing Zone Network

The following will be created:
* Resource Group for Landing Zone Neworking (lz-networking.tf)
* Route Table (lz-networking.tf)
* Peering of Hub and Spoke Networks (hub-spoke-peering.tf)
* Private DNS Zones (dns-zones.tf)
* Application Gateway (app-gateway.tf)
* Subnet for AKS (aks-networking.tf)

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/05-Network-LZ" folder
```
cd ../05-Network-LZ
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
5. Update your the terraform.tfvsars.sample file with this as the value for access_key 
6. Rename the file to terraform.tfvars

Update the rest of the variables in the new terraform.tfvars file as well.

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

```bash
terraform init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
```

```bash
terraform plan
```

```bash
terraform apply
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.

:arrow_forward: [Creation of Supporting Components for AKS](./06-aks-supporting.md)

