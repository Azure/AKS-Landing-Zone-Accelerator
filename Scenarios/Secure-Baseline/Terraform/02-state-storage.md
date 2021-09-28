# Use the Azure CLI to create a storage account to store the Terraform state files.
This storage account will be used to store the state of each deployment step and will be accessed by Terraform to reference values stored in the various deployment state files.

Create some variables to start with

```bash
REGION=<REGION>
STORAGEACCOUNTNAME=<UNIQUENAME>
CONTAINERNAME=akscs
TFSTATE_RG=tfstate
```

Setup environment variable 

```
export ARM_PARTNER_ID=fde452b3-60b3-4ce5-831c-c354d84dacdd
```



Create a Resource Group:
```bash
az group create --name $TFSTATE_RG --location $REGION
```

Create a Storage Account:
```bash
az storage account create -n $STORAGEACCOUNTNAME -g $TFSTATE_RG -l $REGION --sku Standard_LRS
```

Create a Storage Container within the Storage Account:

```bash
az storage container-rm create --storage-account $STORAGEACCOUNTNAME --name $CONTAINERNAME
```

### Next step

To continue with the main deployment click the link below:

:arrow_forward: [Create or Import Azure Active Directory Groups for AKS Cluster Admins and AKS Cluster Users](./03-aad.md)

To continue with CI/CD deployment click on the link below:

:arrow_forward: ​[GitHub Actions for Secure Baseline Scenario with Terraform](./workflows/README.md)

