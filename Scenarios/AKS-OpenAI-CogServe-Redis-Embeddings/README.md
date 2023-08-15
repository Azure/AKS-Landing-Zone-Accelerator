# Build Intelligent Apps on AKS

AKS is a great platform for hosting modern AI based applications for various reasons. It provides a single control plane to host all the assets required to build applications from end to end and even allows the development of appications using a Microservice architecture. What this means is that the AI based components can be separated from the rest of the applications. AKS also allows hosting of some of Azure's Congnitive services as containers withing your cluster, so that you can keep all the endpoints of your applications private as well as manage scaling however you need to. This is a significant advantage when it comes to securing your application. By hosting all components in a single control plane, you can streamline your DevOps process. 

## Core architecture components
In this scenario, we will be building an application that uses various cognitive services. It builds on top of the AKS secure baseline scenario so we will focus on discussing what is different in this scenario. For simplicity and quick deployment, you will be using the AKS construction helper to setup the base AKS environment. You will also be using Bicep to create the additional components that include include Azure Form Recognizer, Translator, Storage account with Queue service as well as Blob storage. In a future revision of this scenario, an option to use Azure Cache for Redis for vector search as opposed to running Redis stack as a container within the AKS cluster. This will shows the flexibility you get when you run your intelligent applications on AKS.

Within the cluster we will have three pods running. One for batch processing of the documents used to update the knowledge base of the conversational AI bot. Another is a customized Redis stack pod that is used for the vector search. The third will the front end application. You can run some of the cognitive services mentioned above as containers in the cluster as well, but for this vanilla installation, we will stick to running them as PaaS service on Azure. For more information about running cognitive services on AKS, please check out [Azure Cognitive Services containers](https://learn.microsoft.com/en-us/azure/cognitive-services/cognitive-services-container-support) page.

![Architecture](../../media/architecture_aks_oai.png)

## Azure and AKS Features
During this workshop, you will be using various Azure and AKS features that make it easy to host intelligent application on AKS. Some of the features are listen below:
* Create embeddings and generate intelligent responses using using Azure OpenAI service
* Read text from PDF documents using Azure form recognizer
* Translate text to a different language as part of AI processing using Azure Translator
* Secure secrets with Azure Key vault
* Provide individual pods access to Key vault secrets using workload identity
* Secure your AKS environment with Azure Policy and Network policy
* Protect access to your application using Application Gateway
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
To Deploy this Scenario, yopu must be registered to use Azure's OpenAI Service.  If you are not already registered, follow the instuctions [here](https://learn.microsoft.com/legal/cognitive-services/openai/limited-access)

> **Warning** 
> Registration may take multiple hours

### Deployment Process

Begin by cloning this repository locally, and change directory to the infrastruture folder
```bash
git clone --recurse-submodules https://github.com/Azure/AKS-Landing-Zone-Accelerator

cd Scenarios/AKS-OpenAI-CogServe-Redis-Embeddings/infrastructure/
```

Ensure you are signed into the `az` CLI (use `az login` if not)

#### Setup environment specific variables

This will set environment variables, including your prefered `Resource Group` name and `Azure Region` for the subsequent steps, and create the `resrouce group` where we will deploy the solution

 > **Important**
 > Set UNIQUESTRING to a value that will prevent your resources from clashing names, recommended combination of your initials, and 2-digit number (eg js07)

```bash
UNIQUESTRING=<Your value here>
RGNAME=embedding-openai-rg
LOCATION=eastus
SIGNEDINUSER=$(az ad signed-in-user show --query id --out tsv)
TENANTID=$(az account show --query tenantId -o tsv)

az group create -l $LOCATION -n $RGNAME
```

#### Infrastructure as Code

Create all the solution resources using the provided `bicep` template, and capture the output environment configration in variables that are used later in the process.

> **NOTE**
> Our bicep template is using the [AKS-Construction](https://github.com/Azure/AKS-Construction) project to provision the AKS Cluster and assosiated cluster services/addons, in addition to the other workload specific resources

```bash
INFRA_RESULT=($(az deployment group create \
        -g $RGNAME  \
        --template-file intelligent-services.bicep \
        --parameters UniqueString=$UNIQUESTRING \
        --parameters signedinuser=$SIGNEDINUSER \
        --query "[properties.outputs.kvAppName.value,properties.outputs.aksOidcIssuerUrl.value,properties.outputs.aksClusterName.value,properties.outputs.blobAccountName.value,properties.outputs.openAIAccountName.value,properties.outputs.openAIURL.value,properties.outputs.formRecognizerAccountName.value,properties.outputs.translatorAccountName.value,properties.outputs.formRecognizerURL.value]" -o tsv \
))
KVNAME=${INFRA_RESULT[0]}
OIDCISSUERURL=${INFRA_RESULT[1]}
AKSCLUSTER=${INFRA_RESULT[2]}
BLOB_ACCOUNTNAME=${INFRA_RESULT[3]}
OPENAI_ACCOUNTNAME=${INFRA_RESULT[4]}
OPENAI_ENDPOINT=${INFRA_RESULT[5]}
FORMREC_ACCOUNT=${INFRA_RESULT[6]}
TRANSLATOR_ACCOUNT=${INFRA_RESULT[7]}
FORMREC_ENDPOINT=${INFRA_RESULT[8]}
```

Note: Verify in Azure OpenAI studio you have available quota for GPT-35-turbo modelotherwise might get error: "code": "InsufficientQuota", "message": "The specified capacity '1' of account deployment is bigger than available capacity '0' for UsageName 'Tokens Per Minute (thousands) - GPT-35-Turbo'."

#### Store the resource keys KeyVault Secrets

OpenAI API, Blob Storage, Form Recognisor and Translator keys will be secured in KeyVault, and passed to the workload using the CSI Secret driver


```bash
az keyvault secret set --name openaiapikey  --vault-name $KVNAME --value $(az cognitiveservices account keys list -g $RGNAME -n $OPENAI_ACCOUNTNAME --query key1 -o tsv)

az keyvault secret set --name formrecognizerkey  --vault-name $KVNAME --value $(az cognitiveservices account keys list -g $RGNAME -n $FORMREC_ACCOUNT --query key1 -o tsv)

az keyvault secret set --name translatekey  --vault-name $KVNAME --value $(az cognitiveservices account keys list -g $RGNAME -n $TRANSLATOR_ACCOUNT --query key1 -o tsv)

az keyvault secret set --name blobaccountkey  --vault-name $KVNAME --value $(az storage account keys list -g $RGNAME -n $BLOB_ACCOUNTNAME --query [1].value -o tsv)
```

Create and record the required federation to allow the CSI Secret driver to use the AD Workload identity, and to update the manifest files.

```bash

CSIIdentity=($(az aks show -g $RGNAME -n $AKSCLUSTER --query [addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId,addonProfiles.azureKeyvaultSecretsProvider.identity.clientId] -o tsv |  cut -d '/' -f 5,9 --output-delimiter ' '))

EMBEDINGAPPID=${CSIIdentity[2]}

az identity federated-credential create --name aksfederatedidentity --identity-name ${CSIIdentity[1]} --resource-group ${CSIIdentity[0]} --issuer ${OIDCISSUERURL} --subject system:serviceaccount:default:serversa
```

### Save variables

```bash
cat << EOF >> .env
CLIENT_ID=$EMBEDINGAPPID
TENANT_ID=$TENANTID
KV_NAME=$KVNAME
OPENAI_API_BASE=$OPENAI_ENDPOINT
LOCATION=$LOCATION
BLOB_ACCOUNT_NAME=$BLOB_ACCOUNTNAME
FORM_RECOGNIZER_ENDPOINT=$FORMREC_ENDPOINT
EOF
```

#### kubernetes Manifests
Change directory to the kubernetes manifests folder, deployment will be done using Kustomize declarations.

```bash
cd ../kubernetes/
```

### Log into the AKS cluster

```bash
az aks get-credentials -g $RGNAME -n $AKSCLUSTER
kubectl get nodes
```


### Deploy the kubernetes resources
```
kubectl apply -k .
```



