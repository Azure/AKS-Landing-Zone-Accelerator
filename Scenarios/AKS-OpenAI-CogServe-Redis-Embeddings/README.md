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

Set environment variables to store your prefered `Resource Group` name and `Azure Region` for the subsequent scripts, and create the `resrouce group` where we will deploy the solution
```bash
    RGNAME=embedding-openai-rg
    LOCATION=eastus
    az group create -l $LOCATION -n $RGNAME
```

Ensure you are signed into the `az` CLI (use `az login` if not), then get your signed in user Id  which will be used to ensure you have access to the cluster & Keyvault to deploy the solution and create the required secrets.
```bash
SIGNEDINUSER=$(az ad signed-in-user show --query id --out tsv)
```


Create the Solution resources using the `bicep` template, including the AKS CLuster (OpenAI, StorageAccount, Translator, Form Reader).

> **NOTE**
> UPDATE the **UniqueString** parameter with your own value (between 3 and 10 characters, alphanumeric only)
> 
> Information: We are using the `AKS-Construction` project to provision the AKS Cluster and assosiated cluster services/addons

```bash
INFRA_RESULT=($(az deployment group create \
        -g $RGNAME  \
        --template-file intelligent-services.bicep \
        --parameters UniqueString=<your unique string> \
        --parameters signedinuser=$SIGNEDINUSER \
        --query "[properties.outputs.kvAppName.value,properties.outputs.aksOidcIssuerUrl.value,properties.outputs.aksClusterName.value]" -o tsv \
))
KVNAME=${INFRA_RESULT[0]}
OIDCISSUERURL=${INFRA_RESULT[1]}
AKSCLUSTER==${INFRA_RESULT[2]}
```

#### Vault the OpenAI API Key into a KeyVault Secret

> **Note** 
> OpenAI API Key will be secured in KeyVault, and passed to the working using the CSI Secret driver


```bash
az keyvault secret set --name openaiapikey  --vault-name $KVNAME --value <OpenAI API Key>
```


Store additional deployment information in environment variables
```bash
EMBEDINGAPPID=$(az aks show -g $RGNAME -n $AKSCLUSTER --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
TENANTID=$(az account show --query tenantId -o tsv)
```

Change directory to the kubernetes manifests folder, and update manifest files with the environment variables

```bash
    cd ../kubernetes/

    sed -i "s/<identity clientID>/$EMBEDINGAPPID/" -i "s/<kv name>/$KVNAME/" -i "s/<tenant ID>/$TENANTID/"  secret-provider-class.yaml

    sed -i "s/<identity clientID>/$EMBEDINGAPPID/" -i "s/<tenant ID>/$TENANTID/" svc-accounts.yaml
```


### Pass environment parameters to the container


Update the `env-configmap.yaml` file with the correct environment variables.

NOTE: Replacing the values in `<...>`.  These values can be taken from the deployments created in the previous steps, as seen in your Azure portal.



### Log into the AKS cluster

```bash
az aks get-credentials -g $RGNAME -n $AKSCLUSTER
kubectl get nodes
```


### Deploy the kubernetes resources
```
kubectl apply -f .
```



