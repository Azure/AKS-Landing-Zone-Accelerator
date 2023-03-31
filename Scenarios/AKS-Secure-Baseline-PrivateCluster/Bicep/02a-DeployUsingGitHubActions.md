# AKS Cluster Deployment via GitHub Actions using OpenID Connect and Bicep (IaC)

For this approach, we will be using GitHub Actions using OpenID Connect and Infrastructure-as-Code (IaC) using Bicep to deploy the AKS cluster, to derive following benefits:

* Infrastructure-as-Code (IaC) - Infrastructure is defined as code, and can be version controlled and reviewed. 
* OpenID Connect - OpenID Connect is an authentication protocol that allows you to connect securely to Azure resources using your GitHub account.
* GitHub Actions - GitHub Actions is a feature of GitHub that allows you to automate your software development workflows.
* Bicep - Bicep is a Domain Specific Language (DSL) for deploying Azure resources declaratively. It aims to drastically simplify the authoring experience with a cleaner syntax, improved type safety, and better support for modularity and code re-use.

This will require performing the following tasks:

1. Forking this repository into your GitHub account
2. Configuring OpenID Connect in Azure
3. Setting Github Actions secrets
4. Triggering the first GitHub Actions workflow

## Forking this repository into your GitHub account

* Fork this [repository](https://github.com/Azure/AKS-Landing-Zone-Accelerator) into your GitHub account by clicking on the "Fork" button at the top right of its page. Use the default name "AKS-Landing-Zone-Accelerator" for this fork in your repo.

## Create AAD Accounts

Use Azure Cloud Shell and Bash (not PowerShell) to run all the commands below in the subscription you want to deploy to.

From the Cloud Shell, run these commands using Bash to create a group in your Azure AD tenant called "AKS Users". Users in this group will have user permissions to the cluster. You will use the value shown for this in a later step.

```bash
az ad group create --display-name "AKS Users" --mail-nickname "AKS-Users"
AKSUSERACCESSPRINCIPALID=$(az ad group show --group "AKS Users" --query id --output tsv)
echo $AKSUSERACCESSPRINCIPALID
```

## Configuring OpenID Connect in Azure

1. Continue to use Bash in the same Cloud Shell to create an Azure AD application using these commands. This is used to deploy the IaC to your Azure Subscription. Make a note of the appId value that is shown by the last step, you will use this value in later steps.

   ```bash
   uniqueAppName=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c10 ; echo '')
   echo $uniqueAppName
   appId=$(az ad app create --display-name $uniqueAppName --query appId --output tsv)
   echo $appId
   ```

2. Create a service principal for the Azure AD app. Make a note of the assigneeObjectId value that is shown by the last step, you will use this value in later steps.

   ```bash
   assigneeObjectId=$(az ad sp create --id $appId --query id --output tsv)
   echo $assigneeObjectId 
   ```

3. Create a role assignment for the Azure AD app. This gives that app contributor access to the currently selected subscription.

   ```bash
   subscriptionId=$(az account show --query id --output tsv)
   az role assignment create --role owner --subscription $subscriptionId --assignee-object-id  $assigneeObjectId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId
   ```

4. Configure a federated identity credential on the Azure AD app.

   You use workload identity federation to configure your Azure AD app registration to trust tokens from an external identity provider (IdP), in this case GitHub.

   In the parameter of the command below, replace `<your-github-username>` with your GitHub username used in your forked repo. If you name your new repository something other than `AKS-Landing-Zone-Accelerator`, you will need to replace `AKS-Landing-Zone-Accelerator` with the name of your repository. Also, if your deployment branch is not `main`, you will need to replace `main` with the name of your deployment branch.

   ```bash
   az ad app federated-credential create --id $appId --parameters '{ "name": "gha-oidc", "issuer": "https://token.actions.githubusercontent.com",  "subject": "repo:<your-github-username>/AKS-Landing-Zone-Accelerator:ref:refs/heads/main", "audiences": ["api://AzureADTokenExchange"], "description": "Workload Identity for AKS Landing Zone Accelerator" }'
   ```

## Create a Personal Access Token (PAT)

You also need a Personal Access Token (PAT) for your forked repo in GitHub. This PAT is used to create a private self-hosted GitHub runner within your repo, which is in turn used to deploy code to your cluster. This is required as your cluster is private and so only a _self-hosted_ GitHub Runner will be able to connect to your cluster in order to deploy code to it. 

Follow these instructions to create a "Classic" PAT: [https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token] The scopes need to include the top-level "repo" and "workflow" scopes, and also "read:org" which is under "admin:org". Make a temporary note of the value: it is used in the next section.

## Register Resource Providers

There are a number of resource providers required by the IaC that need to be registered once in your subscription. Run the commands below.

   ```bash
   az feature register --namespace "Microsoft.Network" --name "AzureFirewallBasic"
   az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
   az feature register --name "EnablePodIdentityPreview" --namespace "Microsoft.ContainerService"
   az feature register --namespace "Microsoft.ContainerService" --name "AKS-AzureKeyVaultSecretsProvider"
   az feature register --namespace "Microsoft.Compute" --name "EncryptionAtHost"
   az feature register --namespace "Microsoft.ContainerService" --name "AKS-ExtensionManager"
   az feature register --namespace "Microsoft.ContainerService" --name "AKS-Dapr"
   az feature register --name "AKS-KedaPreview" --namespace "Microsoft.ContainerService"
            
   az provider register --namespace Microsoft.Network
   az provider register --namespace Microsoft.ContainerService
   az provider register --namespace Microsoft.OperationsManagement
   az provider register --namespace Microsoft.OperationalInsights
   ```

## Setting Github Actions secrets

1. Open your forked Github repository and click on the `Settings` tab.
2. In the left-hand menu, expand `Secrets and variables`, and click on `Actions`.
3. Click on the `New repository secret` button for each of the following secrets:
   * `AZURE_SUBSCRIPTION_ID`(run `az account show --query id --output tsv` to get this value)
   * `AZURE_TENANT_ID` (run `az account show --query tenantId --output tsv` to get the value)
   * `AZURE_CLIENT_ID` (this is the `appId` from the JSON output of the `az ad app create` command above. Use `echo $appId` to get the value from the same terminal used to run the previous commands)
   * `VM_PW` (this is the password you want your VM to be set to)
   * `RUNNER_CFG_PAT` (this is the `Personal Access Token` from earlier step)
   * `AKSUSERACCESSPRINCIPALID` (run `az ad group show --group "AKS Users" --query id --output tsv` to get this value)
   * `EMAIL` (your email address - used by LetsEncrypt to send notifications.)

## Triggering the "Deploy Enterprise Landing Zone Hub & Spoke Infrastructure" GitHub Actions workflow

* Enable GitHub Actions for your repository by clicking on the "Actions" tab, and clicking on the `I understand my workflows, go ahead and enable them` button. You might need to Refresh to see them.
* Click on the `Deploy Enterprise Landing Zone Hub & Spoke Infrastructure` Workflow on the left of the screen (you may need to refresh your Actions in order to see it). Note: Do NOT select the `Deploy Sample Application` Action: this one will be launched _automatically_ and run by your self-hosted GitHub Runner by the first workflow once the first has finished successfully, so does not need to be run manually.
* Click on the `Run workflow` button, accept the default options (leave the checkbox unchecked)

This will trigger the `Deploy Enterprise Landing Zone Hub & Spoke Infrastructure` Action. This will deploy the infrastructure and when complete, will trigger the second Action `Deploy Sample Application` which will deploy a sample application using a self-hosted GitHub runner.

## Testing the Sample Application

The Application Gateway will have been configured for a random DNS name, to which a sample SSL Certificate will have been automatically created to secure the test site. To access your site, first run the command below using cloud shell and bash to get the randomly-generated URL of your site:

   ```bash
   echo 'https://'$(az network public-ip show --name APPGW-PIP --resource-group ESLZ-SPOKE --query dnsSettings.fqdn -o tsv)
   ```

The output of this command will give you the full public URL of your site, for example "https://z910579fa72444b7caeefc4cb439c6ca4.eastus.cloudapp.azure.com". Paste this in to a browser to see your site. You will see warnings indicating that the SSL certificate is not valid, as it is only a test SSL certificate for your randomly-generated domain. You should be able to move past these warnings and view the site running on your secure AKS cluster via HTTPS in your browser.

## Cleaning Up

Execute the following commands using Cloud Shell and Bash to delete everything created by the GitHub Actions:

   ```bash
   az group delete -n ESLZ-HUB -y
   az group delete -n ESLZ-SPOKE -y
   az deployment sub delete -n ESLZ-HUB-AKS
   az deployment sub delete -n ESLZ-AKS-HUB-UDR
   az deployment sub delete -n ESLZ-HUB-VM
   az deployment sub delete -n ESLZ-HUB-RUNNER
   az deployment sub delete -n ESLZ-SPOKE-AKS
   az deployment sub delete -n ESLZ-SPOKE-AKS-SUPPORTING
   az deployment sub delete -n ESLZ-SPOKE-AKS-UDRNSG
   az deployment sub delete -n ESLZ-AKS-CLUSTER
   ```
