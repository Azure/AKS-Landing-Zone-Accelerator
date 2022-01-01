# Create resources for the AKS Cluster

The following will be created:
* Resource Group for AKS
* AKS Cluster
* Log Analytics Workspace
* Managed Identity for AKS Control Plane
* Managed Identity for Application Gateway Ingress Controller
* AKS Pod Identity Assignments - OPTIONAL

Navigate to "/Scenarios/Secure-Baseline/Terraform/07-AKS-cluster" folder
```bash
cd ../07-AKS-cluster 
```

This deployment will need to reference data objects from the Landing Zone and AKS-Supporting deployments and will need access to the pre-existing state files, update the variables as needed.  This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo. 

The default deployment of the cluster uses Azure CNI as the networking plug-in. If Kubenet is desired it can be changed in the variable.tf file. 

Once again, A sample terraform.tfvars.sample file is included. Update the required variables, save it and rename it to **terraform.tfvars**.

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

### Next Steps

:arrow_forward: [Integrate with Key vault](./07-b-keyvault-addon.md)