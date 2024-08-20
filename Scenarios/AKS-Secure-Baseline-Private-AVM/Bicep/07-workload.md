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
   cd
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
   Now login a second time, but this time as root. This is to get around a problem later on where an Azure Container Registry command needs access to AZ access tokens AND the Docker Daemon at the same time - it's just much easier if that part runs as root.
   ```bash
   TENANTID=<tenant id>
   sudo az login -t $TENANTID
   ```

* Ensure you are connected to the correct subscription

   ```bash
   az account set --subscription <subscription id>
   ```

* If you want to control Kubernetes directly from the jumpbox, you will need *kubectl* to be installed and to download the credentials:

  ```bash
  sudo snap install kubectl --classic
  az aks get-credentials  --admin --name akscluster --resource-group aks-lza-spoke
  kubectl get nodes
  ```

## Build Container Images

Clone the sample application Git Repo to the Dev Jumpbox:

1. The AKS Store Demo repo:

```bash
cd
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
#Do this for each app in the directory, there should be 8 in total. Remember to change the tag name for each folder:
# e.g.
# cd makeline-service
# sudo docker build . -t $ACRNAME.azurecr.io/makeline-service:v1
```

Now check all container images have built correctly:
```bash
sudo docker images
```
You should see output similar to
```bash
REPOSITORY                                         TAG       IMAGE ID       CREATED          SIZE
eslzacrguilfdnvzjuum.azurecr.io/virtual-worker     v1        0d6da98b7a1f   12 minutes ago   97MB
eslzacrguilfdnvzjuum.azurecr.io/virtual-customer   v1        a07be343f9d4   13 minutes ago   96.7MB
eslzacrguilfdnvzjuum.azurecr.io/store-front        v1        692284db83ac   15 minutes ago   16.6MB
eslzacrguilfdnvzjuum.azurecr.io/store-admin        v1        9fd83b91a176   17 minutes ago   15MB
eslzacrguilfdnvzjuum.azurecr.io/product-service    v1        2056e083ede1   18 minutes ago   121MB
eslzacrguilfdnvzjuum.azurecr.io/order-service      v1        6d68a60bacc4   25 minutes ago   172MB
eslzacrguilfdnvzjuum.azurecr.io/makeline-service   v1        1a0232d81f29   26 minutes ago   27.6MB
eslzacrguilfdnvzjuum.azurecr.io/ai-service         v1        fddf58277b93   29 minutes ago   431MB
```

## Log into Azure Container Registry

You must now login to the ACR to upload the new images.

> Notice this is being run as root because the command needs access to the Docker daemon (this is why you had to login twice earlier - once as 'azureuser' and once as 'root').
```bash
sudo az acr login -n $ACRNAME
# Login Succeeded
```

## Push the images to the container registry.

```bash
for i in $(sudo docker images | awk 'NR>1 { print $1}') ; do
   (echo "Pushing $i" && sudo docker push $i:v1)
done
```

As well as the custom images uploaded above, there are additional images which we can just import from a public repository. Import these using the `az acr import` command:

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
cd $HOME/AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-Private-AVM/Bicep/07-Workload

helm install monkey-magic ./shoppingDemo --set containerRegistry=$ACRNAME.azurecr.io
```
After deployment, check the pods have created correctly:
```bash
kubectl get pods
```
A correct installation looks like this:
```bash
NAME                                READY   STATUS    RESTARTS   AGE
makeline-service-57c7b44d6b-mqc97   1/1     Running   0          107s
mongodb-0                           1/1     Running   0          107s
order-service-6df845965-8kg27       1/1     Running   0          107s
product-service-79f7cc5cd-fw6r2     1/1     Running   0          107s
rabbitmq-0                          1/1     Running   0          107s
store-admin-6d5cf5676-9cmrj         1/1     Running   0          107s
store-front-56b745cbf-57f27         1/1     Running   0          107s
virtual-customer-59d74777d6-qvwkd   1/1     Running   0          107s
virtual-worker-69576c848b-49g24     1/1     Running   0          107s
```

### Test the application

To test access to the new application, get the EXTERNAL-IP of the store front service then open the address from a browser:
```bash
kubectl get service/store-front
```

XXXXXXXXXXXXXXXXXXXXXX

TODO: Setup ingress via AppGW and point to the store-front service

XXXXXXXXXXXXXXXXXXXXXX