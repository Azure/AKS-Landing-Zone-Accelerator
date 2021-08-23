# Create the Landing Zone Network

The following will be created:
* Resource Group for Landing Zone Neworking (lz-networking.tf)
* Route Table (lz-networking.tf)
* Peering of Hub and Spoke Networks (hub-spoke-peering.tf)
* Private DNS Zones (dns-zones.tf)
* Application Gateway (app-gateway.tf)
* Subnet for AKS (aks-networking.tf)

Navigate to "/Scenarios/Secure-Baseline/Terraform/05-Network-LZ" folder
```
cd /Scenarios/Secure-Baseline/Terraform/05-Network-LZ
```

In the "provider.tf" file update the backend settings to reflect the storage account created for Terraform state management.  Do not change the "key" name, as it's referenced later in the deployment files. 

In the "variables.tf" file, update the defaults to reflect the tags and prefix you'd like to use.  
This deployment will need to reference data objects from the Hub deployment and will need access to the pre-existing state file, update the variables as needed.  This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. A sample terraform.tfvars file is included. 


Once the files are updated, deploy using Terraform Init, Plan and Apply. 