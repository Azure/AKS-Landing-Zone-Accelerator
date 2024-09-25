# Deploy to Azure with an All in One Bicep Template

## Introduction 
The individual markdown files in the [Bicep](../Bicep/) folder are a great way to learn the process of deploying a baseline private AKS cluster using Azure Verified Modules, especially if you want to deploy each of them manually from the command line. 

However if you need to deploy multiple clusters, manual deployment can become rather tedious. A better option is to use the [Deploy to Azure](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-to-azure-button) button which fully automates the process.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAKS-Landing-Zone-Accelerator%2Fdd-all-in-one-avm%2FScenarios%2FAKS-Secure-Baseline-Private-AVM%2FAll-in-One-Bicep%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAKS-Landing-Zone-Accelerator%2Fdd-all-in-one-avm%2FScenarios%2FAKS-Secure-Baseline-Private-AVM%2FAll-in-One-Bicep%2Fmain.portal.ui.json)

This button links to a single all-in-one template which is located in this same folder as the page you are reading.

> At time of writing, the Azure Portal cannot directly work with Bicep files which have been linked with the **Deploy to Azure** button. Therefore after every change to the file, a developer must run `bicep build main.bicep --outfile main.json` to transpile this into a traditional ARM json template. It is this latter file which the Azure Portal downloads and deploys.

## Running the deployment

### Step 1 - Create security group for the AKS Admins.

In [Prerequisites and Microsoft Entra ID](../Bicep/02-eid.md) there are two AAD Groups (Entra Groups) which are created using the Azure CLI. The GUIDs of these are then used during the AKS cluster creation to control admin access to the cluster.

> Despite creating two groups, only one is actually used during cluster creation.

A security group to control AKS access must be manually created before running the "Deploy to Azure" template. Choose either of the following two methods:

* [Create a new AAD security group](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-manage-groups) called **AKS Admins** using the Azure Portal.

or

* From an Azure CLI command line, run `az ad group create --display-name "AKSAdmins" --mail-nickname "AKSAdmins"`.

In either case, make a note of the GUID associated with this new group as you will need to provide it whilst deploying the template.

> Don't forget to add your own user account as a member of the new group.

There is only a few steps required to deploy the template:

### Step 2 - Launch the template to create the infrastructure.

#### Option 1: Using the Deploy to Azure Button

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#view/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAKS-Landing-Zone-Accelerator%2Fdd-all-in-one-avm%2FScenarios%2FAKS-Secure-Baseline-Private-AVM%2FAll-in-One-Bicep%2Fmain.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAKS-Landing-Zone-Accelerator%2Fdd-all-in-one-avm%2FScenarios%2FAKS-Secure-Baseline-Private-AVM%2FAll-in-One-Bicep%2Fmain.portal.ui.json)

Right-click the blue button above and choose *Open link in new tab* to open the Azure Portal. This will download the template from GitHub and open a custom form from where you can edit several of the key default parameter values built into the template.

On the **AKS Cluster creation settings** tab, locate the empty field **AKS Admin Group GUID** and enter the GUID which you generated in step 1.

Now press the **Review + Create** button, followed by **Create** to start the deployment.

> You may use the button below to run the template with an auto-generated UI. This provides access to ALL the configurable settings in the template.
>
> [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAKS-Landing-Zone-Accelerator%2Fdd-all-in-one-avm%2FScenarios%2FAKS-Secure-Baseline-Private-AVM%2FAll-in-One-Bicep%2Fmain.json)

#### Option 2: Using Azure CLI

Log into your Azure CLI and run the command below

```bash
LOCATION=<Your azure region>
```

```bash
az deployment sub create --location $LOCATION --template-file main.bicep --parameters @main.json --name aksLZAAllInOne
```


   
### Step 3 - Deploy the application to AKS.
The final stage of deployment is to [Deploy a Basic Workload using the AKS-Store-Demo Application](../Bicep/07-workload.md). As this requires running command line tools to build containers and deploy a configuration to AKS, it's rather difficult to do from Bicep, therefore [follow the manual steps to deployment the application](../Bicep/07-workload.md).
