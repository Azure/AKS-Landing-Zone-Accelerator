# Create Azure Active Directory Groups for AKS
Before creating the Azure Active Directory integrated cluster, two groups must exist that can be later mapped to the Built-In Roles of "Azure Kubernetes Service Cluster User Role" and "Azure Kubernetes Service RBAC Cluster Admin". You will add yourself to the AKS Admin group, but the other group for users will not be used in this demo. It is included to demonstration a best practice for creating two distinct groups of users who can access the cluster. 

Navigate to "\Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\03-AAD-create" folder.
```
cd .\Scenarios\AKS-Secure-Baseline-PrivateCluster\Terraform\03-AAD-create
```

In the "variables.tf" file, update the security group and defaults to reflect the display names as needed to match existing groups. Also, update Terraform State variables to match storage account used for state file backend config. Key value is set in provider.tf.

### Update the following values to your PowerShell instance:
We will be running the commands using the service principal you created in [prerequisites/step 1](./01-prerequisites.md). You will need your SPN client ID, SPN tenant id and client secret. 
Create the following variables for ease of use during deployment. 

```PowerShell
$backendResourceGroupName=""
$backendStorageAccountName=""
$backendContainername=""
$layerNametfstate="aad"
$env:ARM_CLIENT_ID = "00000000-0000-0000-0000-000000000000"
$env:ARM_CLIENT_SECRET = "12345678-0000-0000-0000-000000000000"
$env:ARM_TENANT_ID = "10000000-0000-0000-0000-000000000000"
$env:ARM_SUBSCRIPTION_ID = "20000000-0000-0000-0000-000000000000"
```
Deploy using Terraform Init, Plan and Apply. 

```PowerShell 
terraform init -input=false -backend-config="resource_group_name=$backendResourceGroupName" -backend-config="storage_account_name=$backendStorageAccountName" -backend-config="container_name=$backendContainername" -backend-config="key=$layerNametfstate"
```

``` PowerShell 
terraform plan -out $layerNametfstate
```

```PowerShell 
terraform apply --auto-approve $layerNametfstate
```

If you get an error about changes to the configuration, go with the `-reconfigure` flag option.
If you get an error about list of available provider versions, go with the `-upgrade` flag option to allow selection of new versions.

## Ensure you are part of the AAD Admin group you just created

1. Go to Azure portal and type AAD
2. Select **Azure Active Directory**
3. Click on **Groups** in the left blade
4. Select the Admin User group you just created. For the default name, this should be *AKS App Admin Team 2*
5. Click on **Members** in the left blade
6. Click **+ Add members**
7. Enter your name in the search bar and select your user(s)
8. Click **Select**

# Next step

:arrow_forward: [Creation of Hub Network & its respective Components](./04-network-hub.md)