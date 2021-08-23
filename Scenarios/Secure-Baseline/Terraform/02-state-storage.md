# Use the Azure CLI to create a storage account to store the Terraform state files.
This storage account will be used to store the state of each deployment step and will be accessed by Terraform to reference values stored in the various deployment state files.

Create a Resource Group:
```
az group create --name tfstate --location <REGION>
```

Create a Storage Account:
```
az storage account create -n <UNIQUENAME> -g tfstate -l <REGION> --sku Standard_LRS
```

Create a Storage Container within the Storage Account:

```
az storage container-rm create --storage-account <BLOB_NAME> --name <CONTAINER_NAME>
```

### Next step

:arrow_forward: [Create or Import Azure Active Directory Groups for AKS Cluster Admins and AKS Cluster Users](./03-aad.md)