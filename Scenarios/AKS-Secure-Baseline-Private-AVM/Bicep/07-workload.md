# Deploy a Basic Workload using the AKS-Store-Demo Application

This application consists of a group of containerized microservices that can be easily deployed into an Azure Kubernetes Service (AKS) cluster. This is meant to show a realistic scenario using a polyglot architecture, event-driven design, and common open source back-end services (eg - RabbitMQ, MongoDB). The application also leverages OpenAI's GPT-3 models to generate product descriptions. You can find out more about the application at https://github.com/Azure-Samples/aks-store-demo

As the infrastructure has been deployed in a private AKS cluster setup with private endpoints for the container registry and other components, you will need to perform the application container build and the publishing to the Container Registry from the Dev Jumpbox in the Hub VNET, connecting via the Bastion Host service.

 If your computer is connected to the hub network, you may be able to just use that as well. The rest of the steps can be performed on your local machine by using AKS Run commands which allow access into private clusters using RBAC. This will help with improving security and will provide a more user-friendly way of editing YAML files.

## Connecting to the Bastion Host

1. Use Bastion Host to connect to the jumpbox.
2. Enter the username and password (azureuser/Password123). If you have used a public key, then select upload private key (corresponding to the public key) to connect.
3. Once you connect ensure you permit the site to read the content of your clipboard.

* Clone the repository to the jumpbox.

   ```bash
   git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator/
   ```

* Run the script below to install the required tools (Az CLI, Docker, Kubectl, Helm etc). Navigate to "07-Workload" folder.

   ```bash
   cd AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-Private-AVM/Bicep/07-Workload
   chmod +x script.sh
   sudo ./script.sh
   ```

* Login to Azure

   ```bash
   TENANTID=<tenant id>
   az login -t $TENANTID
   ```

* Ensure you are connected to the correct subscription

   ```bash
   az account set --subscription <subscription id>
   ```

* If you want to control Kubernetes directly from the jumpbox, you will need *kubectl* to be installed and to download the credentials:

  ```bash
  # sudo snap install kubectl --classic
  az aks get-credentials  --admin --name akscluster --resource-group aks-lza-spoke
  kubectl get nodes
  ```

## Build Container Images

Clone the sample application Git Repo to the Dev Jumpbox:

1. The AKS Store Demo repo:

```bash
cd ..
git clone https://github.com/Azure-Samples/aks-store-demo
```

Navigate to each application code directory, build and tag the containers with the name of your Azure Container Registry and push the images to ACR.

*NOTE: If you are deploying to Azure US Government, use '.azurecr.us' instead of '.azurecr.io' in the commands below.*

```bash
# enter the name of your ACR below
SPOKERG=AKS-LZA-SPOKE
ACRNAME=$(az acr list -g $SPOKERG --query [0].name -o tsv)

cd aks-store-demo/src
# Change directory into each app folder and build/tag the image. Example:
cd ai-service
sudo docker build . -t $ACRNAME.azurecr.io/ai-service:v1
#Do this for each app in the directory. There should be 8 in total.

```

Log into ACR (Azure Container Registry)

> :warning: If you run into issues logging into ACR, ensure your user account has the right RBAC permissions on the ACR resource and that the Jumpbox can reach the ACR from a networking standpoint.

```bash
sudo az acr login -n $ACRNAME
```

Push the images into the container registry. Ensure you are logged into the Azure Container Registry, you should show a successful login from the command above.

*NOTE: If you are deploying to Azure US Government, use '.azurecr.us' instead of '.azurecr.io' in the commands below.*

```bash
for i in $(sudo docker images | awk 'NR>1 { print $1}') ; do
   (echo "Pushing $i" && sudo docker push $i:v1)
done
```

In addition to the above, there are additional images which we can just import from a public repository. Import these using the `az acr import` command:

```bash
az acr import --name $ACRNAME --source mcr.microsoft.com/mirror/docker/library/mongo:4.2 --image mongo:4.2
az acr import --name $ACRNAME --source mcr.microsoft.com/mirror/docker/library/rabbitmq:3.10-management-alpine --image rabbitmq:3.10-management-alpine
```

You should also connect your AKS Cluster to the Azure Container Registry (ACR) so when it attempts to pull images it can authenticate correctly:

```bash
az aks update --name "aksCluster" --resource-group "AKS-LZA-SPOKE" --attach-acr $ACRNAME
```

Now deploy the application using the HELM chart. Make sure to update the value of the containerRegistry in the command below to your ACR name:

```bash
cd 07-Workload
helm install monkey-magic ./shoppingDemo --set containerRegistry=$ACRNAME.azurecr.io
```

XXXXXXXXXXXXXXXXXXXXXX

TODO: Setup ingress via AppGW and point to the store-front service

XXXXXXXXXXXXXXXXXXXXXX


