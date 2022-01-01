## GitHub Actions for Secure Baseline Scenario with Terraform

### Fork this repo 

To use GitHub Actions, you will need to fork this repo into your account so that you can make changes to the repo on GitHub as well as create secrets that will be required to make the deployments work. After you clone the repo, copy the content (not including the folder) of the *workflow-files* folder in this directory into the *.github/workflows* folder in the repo root folder. 

### Create storage account for Terraform state files

The next step would be to create a storage account that will be used to store the terraform state files. For instructions on how to do that check out the state storage step in the main deployment section

:arrow_forward: [Create Storage Account for State Files](../02-state-storage.md)

#### Get storage account access key

1. Go to Azure portal and click on the storage account you just created
2. In the left blade click on **Access keys**
3. Click on **Show keys** at the top of the resulting page
4. Copy one of the keys (Key field) and save it somewhere for later use



## Create or Import Azure Active Directory Groups for AKS

Next, create or import Azure Active directory groups who's members will have access to the AKS cluster you are about to build. This cannot be done as part of the pipeline because the Service principal the GitHub runner is using does not have tenant AAD access. Follow the instructions in the link below:

:arrow_forward: ​[Create or Import Azure Active Directory Groups for AKS Cluster Admins and AKS Cluster Users](../03-aad.md)

## Create a Service Principal for the GitHub runner

The GitHub runner that will create your Azure Resources using GitHub actions needs to have access to create these resources in your subscription. For that reason, you need to create a service principal (SP) or use an existing one that has both User Access admin as well as Contribution role at the subscription in which you will be deploying the resources. 

```
az ad sp create-for-rbac --name ServicePrincipalName
```

When the service principal is created, it will output details about the service principal. Copy the details and save it somewhere for future use.

### Grant SP Access at Subscription Level

1. Go to the Azure portal and find the subscription you intent to deploy the resources into
2. Click on Access control (IAM) in the left blade
3. Click on **+ Add** and then click on **Add role assignment**
4. Under **Role** select Contributor
5. Under **Select** search for and choose the SP you just created
6. Click **Save**
7. Repeat the same steps to grant the SP the **User Access Administrator** role

## Create GitHub Secrets

1. In your GitHub repo click on Settings > Secrets > New repository secret
2. Create a secret named **AZURE_CLIENT_ID** and for the value use the value of **appId** in the output you saved earlier
3. Create a secret named **AZURE_CLIENT_SECRET** and for the value use the value of **password** in the output you saved earlier
4. Create a secret named **AZURE_SUB_ID** and for the value use your subscription id
5. Create a secret named **AZURE_TENANT_ID** and for the value use your tenant id 
6. Create a secret named **ADMIN_PASSWORD** and enter a strong password for the bastion VM that will be created as part of the pipeline
7. Create a secret named **ACCESS_KEY** and enter the storage account access key you saved earlier
8. Create a secret named **DEPLOYMENT_SP** and enter the same value you entered for AZURE_CLIENT_ID above

## Update Deployment files

In the *.github/workflows/deployInfrastructure.yml* (the pipeline that deploys stages 4,5 and 6 in our deployment step) file, update the values for TF_VAR_hub_prefix, TF_VAR_lz_prefix, TF_VAR_prefix,TF_VAR_state_sa_name, TFSTATE_RG, STORAGEACCOUNTNAME and CONTAINERNAME and save the file. 

   **IMPORTANT**: Make sure you update the value for the two jobs in the pipeline.

## Deploy the pipeline

Once the files have been updated and saved. Commit the changes and push to your repo on GitHub. The pipeline is set to automatically get triggered whenever there is a new push to  the main branch of the repository. Watch the deployment complete and address any errors that may show up before proceeding with the next step.

### Up next: Integrate the cluster with Key vault

:arrow_forward: [Integrate with Key vault](../07-b-keyvault-addon.md)
