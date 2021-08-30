# Create or Import Azure Active Directory Groups for AKS
Before creating the Azure Active Directory integrated cluster, groups must be created that can be later mapped to the Built-In Roles of "Azure Kubernetes Service Cluster User Role" and "Azure Kubernetes Service RBAC Cluster Admin".

Depending on the needs of your organization, you may have a choice of existing groups to use or a new groups may need to be created for each cluster deployment.  

Navigate to "/Scenarios/Secure-Baseline/Terraform/03-AAD" folder
```
cd ./Scenarios/Secure-Baseline/Terraform/03-AAD
```

In the "provider.tf" file update the backend settings to reflect the storage account created for Terraform state management.  Do not change the "key" name, as it's referenced later in the deployment files. 

In the "ad_groups.tf" file, determine if you will be referencing groups that already exist in your Active Directory tenant, or if new ones will be created.  The code will create new groups by default and includes an alternative section (commented out) that can be used to reference existing groups. Adjust the code to meet your requirements. The code must create and/or import two groups and output the object IDs to the state file. 

In the "variables.tf" file, update the defaults to reflect the display names as needed to either match existing groups or create names that fit your requirements.  

Once the files are updated, deploy using Terraform Init, Plan and Apply. 

```
terraform init
```

```
terraform plan
```

```
terraform apply
```

### Next step

:arrow_forward: [Creation of Hub Network & its respective Components](./04-network-hub.md)