## GitHub Actions for Secure Baseline Scenario with Terraform

### Fork this repo 

To use GitHub Actions, you will need to fork this repo into your account so that you can make changes to the repo on GitHub as well as create secrets that will be required to make the deployments work. After you clone the repo, copy the content (not including the folder) of the *workflow-files* folder in this directory into the *.github/workflows* folder in the repo root folder. 

### Create storage account for Terraform state files

The next step would be to create a storage account that will be used to store the terraform state files. For instructions on how to do that check out the state storage step in the main deployment section

:arrow_forward: [Create Storage Account for State Files](../02-state-storage.md)

## Create or Import Azure Active Directory Groups for AKS

Next, create or import Azure Active directory groups who's members will have access to the AKS cluster you are about to build following instructions in the link below:

:arrow_forward: ​[Create or Import Azure Active Directory Groups for AKS Cluster Admins and AKS Cluster Users](../03-aad.md)

## Create a Service Principal for the GitHub runner

The GitHub runner that will create your Azure Resources using GitHub actions needs to have access to create these resources in your subscription. For that reason, you need to create a service principal (SP) or use an existing one that has both User Access admin as well as Contribution role at the subscription in which you will be deploying the resources. 

```
az ad sp create-for-rbac --name ServicePrincipalName
```

### Grant SP Access at Subscription Level

1. Go to the Azure portal and find the subscription you intent to deploy the resources into
2. Click on Access control (IAM) in the left blade
3. Click on **+ Add** and then click on **Add role assignment**
4. Under **Role** select Contributor
5. Under **Select** search for and choose the SP you just created
6. Click **Save**
7. Repeat the same steps to grant the SP the **User Access Administrator** role

### Get the ID of your SP

1. In Azure portal search for and select **Azure Active Directory**
2. In the **Search your tenant** search bar enter the name of your SP and select it
3. Copy the **Application ID** in the resulting page and save it somewhere. You will need this ID later

