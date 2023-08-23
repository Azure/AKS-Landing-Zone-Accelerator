# Build Intelligent Apps on AKS

AKS is a great platform for hosting modern AI based applications for various reasons. It provides a single control plane to host all the assets required to build applications from end to end and even allows the development of applications using a Microservice architecture. What this means is that the AI based components can be separated from the rest of the applications. AKS also allows hosting of some of Azure's AI services as containers withing your cluster, so that you can keep all the endpoints of your applications private as well as manage scaling however you need to. This is a significant advantage when it comes to securing your application. By hosting all components in a single control plane, you can streamline your DevOps process. 

## Core architecture components
In this scenario, we will be building an application that uses various Azure AI services. It builds on top of the AKS secure baseline scenario so we will focus on discussing what is different in this scenario. For simplicity and quick deployment, you will be using the AKS construction helper to setup the base AKS environment. You will also be using Bicep to create the additional components that include Azure Form Recognizer, Translator, Storage account with Queue service as well as Blob storage. In a future revision of this scenario, an option to use Azure Cache for Redis for vector search as opposed to running Redis stack as a container within the AKS cluster. This will shows the flexibility you get when you run your intelligent applications on AKS.

Within the cluster we will have three pods running. One for batch processing of the documents used to update the knowledge base of the conversational AI bot. Another is a customized Redis stack pod that is used for the vector search. The third will the front end application. You can run some of the AI services mentioned above as containers in the cluster as well, but for this vanilla installation, we will stick to running them as PaaS service on Azure. For more information about running Azure AI services on AKS, please check out [Azure Cognitive Services containers](https://learn.microsoft.com/en-us/azure/cognitive-services/cognitive-services-container-support) page.

![Architecture](../../media/architecture_aks_oai.png)

## Azure and AKS Features
During this workshop, you will be using different Azure and AKS features that make it easy to host intelligent application on AKS. Some of the features are listen below:
* Create embeddings and generate intelligent responses using Azure OpenAI service
* Read text from PDF documents using Azure form recognizer
* Translate text to a different language as part of AI processing using Azure Translator
* Secure secrets with Azure Key vault
* Provide individual pods access to Key vault secrets using workload identity
* Secure your AKS environment with Azure Policy and Network policy
* Protect access to your application using Application Web routing Ingress Controller
* Automatically scale your application with cluster autoscaler and horizontal pod autoscaler
* Queue jobs using Azure queue
* Store vectors of your knowledge base and perform vector search using a pod running on AKS
* Store domain knowledge on Azure blog storage
* Load balance traffic across various pods using Azure Load balancer and Nginx
* Limit network access using network security groups

## Azure OpenAI Embeddings QnA

A simple web application for a OpenAI-enabled document search. This repo uses Azure OpenAI Service for creating embeddings vectors from documents. For answering the question of a user, it retrieves the most relevant document and then uses GPT-3 to extract the matching answer for the question. For more information about this application and how to run it on other Azure services, please check out the [Azure OpenAI Embeddings QnA](https://github.com/azure-samples/azure-open-ai-embeddings-qna) repository.

## Deploy this Scenario

### Pre-requisite
To Deploy this Scenario, you must be registered to use Azure's OpenAI Service.  If you are not already registered, follow the instructions [here](https://learn.microsoft.com/legal/cognitive-services/openai/limited-access)

> **Warning** 
> Registration may take multiple hours.

> **Note** 
> There are troubleshooting instructions at the end of this walkthrough.

### Deployment Process

Begin by cloning this repository locally, and change directory to the infrastructure folder.
```bash
git clone --recurse-submodules https://github.com/Azure/AKS-Landing-Zone-Accelerator

cd Scenarios/AKS-OpenAI-CogServe-Redis-Embeddings/infrastructure/
```

Ensure you are signed into the `az` CLI (use `az login` if not)

#### Setup environment specific variables

This will set environment variables, including your preferred `Resource Group` name and `Azure Region` for the subsequent steps, and create the `resource group` where we will deploy the solution.

 > **Important**
 > Set UNIQUESTRING to a value that will prevent your resources from clashing names, recommended combination of your initials, and 2-digit number (eg. js07)

```bash
UNIQUESTRING=<Your value here>
RGNAME=embedding-openai-rg
LOCATION=eastus
SIGNEDINUSER=$(az ad signed-in-user show --query id --out tsv)

az group create -l $LOCATION -n $RGNAME
```

#### Infrastructure as Code

Create all the solution resources using the provided `bicep` template and capture the output environment configuration in variables that are used later in the process.

> **NOTE**
> Our bicep template is using the [AKS-Construction](https://github.com/Azure/AKS-Construction) project to provision the AKS Cluster and associated cluster services/addons, in addition to the other workload specific resources.

 > **Important**
 > Ensure you have enough quota to deploy the gpt-35-turbo and text-embedding-ada-002 models before running the command below. Failure to do this will lead to an "InsufficientQuota" error in the model deployment. Most subscriptions have quota of 1 of these models, so if you already have either of those models deployed, you might not be able to deploy another one in the same subscription and you might have to use that deployment as your model instead to proceed.

```bash
INFRA_RESULT=($(az deployment group create \
        -g $RGNAME  \
        --template-file intelligent-services.bicep \
        --parameters UniqueString=$UNIQUESTRING \
        --parameters signedinuser=$SIGNEDINUSER \
        --query "[properties.outputs.kvAppName.value,properties.outputs.aksOidcIssuerUrl.value,properties.outputs.aksClusterName.value,properties.outputs.blobAccountName.value,properties.outputs.openAIAccountName.value,properties.outputs.openAIURL.value,properties.outputs.formRecognizerAccountName.value,properties.outputs.translatorAccountName.value,properties.outputs.formRecognizerURL.value]" -o tsv \
))
KV_NAME=${INFRA_RESULT[0]}
OIDCISSUERURL=${INFRA_RESULT[1]}
AKSCLUSTER=${INFRA_RESULT[2]}
BLOB_ACCOUNT_NAME=${INFRA_RESULT[3]}
OPENAI_ACCOUNTNAME=${INFRA_RESULT[4]}
OPENAI_API_BASE=${INFRA_RESULT[5]}
FORMREC_ACCOUNT=${INFRA_RESULT[6]}
TRANSLATOR_ACCOUNT=${INFRA_RESULT[7]}
FORM_RECOGNIZER_ENDPOINT=${INFRA_RESULT[8]}
```

 > **Important**
 > Ensure you those commands above captured the correct values for the environment variables by using the echo command, otherwise you might run into errors in the next few commands.

Note: Verify in Azure OpenAI studio you have available quota for GPT-35-turbo model, otherwise you might get error: "code": "InsufficientQuota", "message": "The specified capacity '1' of account deployment is bigger than available capacity '0' for UsageName 'Tokens Per Minute (thousands) - GPT-35-Turbo'."

#### Store the resource keys Key Vault Secrets

OpenAI API, Blob Storage, Form Recognizer and Translator keys will be secured in Key Vault, and passed to the workload using the CSI Secret driver

> Note: If you get a bad request error in any of the commands below, then it means the previous commands did not serialize the environment variable correctly. Use the echo command to get the name of the AI services used in the commands below and run the commands by replacing the environment variables with actual service names.

```bash
az keyvault secret set --name openaiapikey  --vault-name $KV_NAME --value $(az cognitiveservices account keys list -g $RGNAME -n $OPENAI_ACCOUNTNAME --query key1 -o tsv)

az keyvault secret set --name formrecognizerkey  --vault-name $KV_NAME --value $(az cognitiveservices account keys list -g $RGNAME -n $FORMREC_ACCOUNT --query key1 -o tsv)

az keyvault secret set --name translatekey  --vault-name $KV_NAME --value $(az cognitiveservices account keys list -g $RGNAME -n $TRANSLATOR_ACCOUNT --query key1 -o tsv)

az keyvault secret set --name blobaccountkey  --vault-name $KV_NAME --value $(az storage account keys list -g $RGNAME -n $BLOB_ACCOUNT_NAME --query [1].value -o tsv)
```

Create and record the required federation to allow the CSI Secret driver to use the AD Workload identity, and to update the manifest files.

```bash


CSIIdentity=($(az aks show -g $RGNAME -n $AKSCLUSTER --query [addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId,addonProfiles.azureKeyvaultSecretsProvider.identity.clientId] -o tsv |  cut -d '/' -f 5,9 --output-delimiter ' '))

CLIENT_ID=${CSIIdentity[2]}
IDNAME=${CSIIdentity[1]} 
IDRG=${CSIIdentity[0]} 

az identity federated-credential create --name aksfederatedidentity --identity-name $IDNAME --resource-group $IDRG --issuer $OIDCISSUERURL --subject system:serviceaccount:default:serversa

```

#### Kubernetes Manifests
Change directory to the Kubernetes manifests folder, deployment will be done using Kustomize declarations.

```bash
cd ../kubernetes/
```

### Log into the AKS cluster

```bash
az aks get-credentials -g $RGNAME -n $AKSCLUSTER
kubectl get nodes


INGRESS_IP=$(kubectl get svc nginx -n app-routing-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

### Save variables in a new .env file

```bash
cat << EOF >> .env
CLIENT_ID=$CLIENT_ID
TENANT_ID=$(az account show --query tenantId -o tsv)
KV_NAME=$KV_NAME
OPENAI_API_BASE=$OPENAI_API_BASE
LOCATION=$LOCATION
BLOB_ACCOUNT_NAME=$BLOB_ACCOUNT_NAME
FORM_RECOGNIZER_ENDPOINT=$FORM_RECOGNIZER_ENDPOINT
DNS_NAME=openai-$UNIQUESTRING.$INGRESS_IP.nip.io
EOF
```


### Deploy the Kubernetes resources
Option 1:
```bash
kustomize build . > deploy-all.yaml
kubectl apply -f deploy-all.yaml
```
Option 2:
```
kubectl apply -k .
```

### Test the app
Get the URL where the app can be reached
```bash
kubectl get ingress
```
1. Copy the url under **HOSTS** and paste it in your browser. 
1. Try asking the chatbot a domain specific question and notice it fail to answer it correctly. 
1. Click on the `Add Document` tab in the left pane and either upload a PDF with domain information you would like to ask the chatbot about or copy and paste text containing the knowledge base in `Add text to the knowledge base` section, then click on `Compute Embeddings`
1. Head back to the **Chat** tab, try asking the same question again and watch the chatbot answer it correctly

### Troubleshooting
#### Bad request errors
Depending on type of terminal you are using, the command to create environment variables by querying the **INFRA_RESULT** variable that gets created with the deployment might not work properly. You will notice then when you get bad request errors when running subsequent commands. Try using the **echo** command to print the values of those environment variables into your terminal and replace the environment variables like `$OPENAI_ACCOUNTNAME` and `$OIDCISSUERURL` with the actual string values.

#### Pod deployment issues
If you notice that the api pod is stuck in *ContainerCreating* status, chances are that the federated identity was not created properly. To fix this, ensure that the "CSIIdentity" environment variable was created properly. You should then run the "az identity federated-credential create" command again using string values as opposed to environment variables. You can find the string values by using the **echo** command to print the environment variables in your terminal. It is the API deployment that brings the secrets from Key vault into the AKS cluster, so the other two pods require the API pod to be in a running state before they can start as well since they require the secrets.

#### 
