# Create Public DNS Record to publish and invoke endpoitns/apps hostend in the AKS Clusters

The following will be created:
* A Records

Navigate to "/Scenarios/AKS-Secure-Baseline-PrivateCluster/Terraform/08-DNS-Records" folder
```bash
cd ../08-DNS-Records
```

This deployment will need to reference data objects from the Spoke deployment and will need access to the pre-existing state file, update the variables as needed. This deployment will also need to use a storage access key (from Azure) to read the storage account data.  This is a sensitive variable and should not be committed to the code repo.

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

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.

:arrow_forward: [CleanUp](./10-cleanup.md)