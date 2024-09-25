# Deploy a Basic Workload using the AKS-Store-Demo Application

This application consists of a group of containerized microservices that can be easily deployed into an Azure Kubernetes Service (AKS) cluster. This is meant to show a realistic scenario using a polyglot architecture, event-driven design, and common open source back-end services (eg - RabbitMQ, MongoDB). The application also leverages OpenAI's GPT-3 models to generate product descriptions. You can find out more about the application at https://github.com/Azure-Samples/aks-store-demo

As the infrastructure has been deployed in a private AKS cluster setup with private endpoints for the container registry and other components, you will need to perform the application container build and the publishing to the Container Registry from the Dev Jumpbox in the Hub VNET, connecting via the Bastion Host service.

 If your computer is connected to the hub network, you may be able to just use that as well. The rest of the steps can be performed on your local machine by using AKS Run commands which allow access into private clusters using RBAC. This will help with improving security and will provide a more user-friendly way of editing YAML files.

## Connecting to the Bastion Host

The first major step to deploying the application is to connect to the jumpbox inside the private network and authenticate to Azure and the AKS cluster.

1. From the *jumpbox* resource in the *AKS-LZA-SPOKE* resource group, connect to the VM using the **Connect via Bastion** option using the credentials provided in the Bicep template (azureuser/Password123).

1. If prompted, allow the browser to read the contents of your clipboard.

1. From the jumpbox command line, clone the *aks-landing-Zone-Accelerator* repository which contains some setup scripts needed shortly.

   ```bash
   cd

   git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator/
   ```

1. Run the setup script to apply the latest updates to the jumpbox and to install other required packages.

   ```bash
   cd AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-Private-AVM/Bicep/07-Workload

   chmod +x script.sh

   sudo ./script.sh
   ```
   NOTE: You might need to hit Enter when it says "Restarting services..."

1. Login to Azure and select your subscription

   ```bash
   TENANTID=<your AAD tenant id>

   az login -t $TENANTID
   ```
   If your account has access to multiple subscriptions, you will be prompted to select the one you wish to use.

1. If you selected the wrong subscription, it can be set correctly as shown.

   ```bash
   az account set --subscription <subscription id>
   ```

1. Set environment variables

   ```bash
      # Enter the name of your ACR below
      SPOKERG=AKS-LZA-SPOKE
      AKSCLUSTERNAME=$(az aks list -g $SPOKERG --query [0].name -o tsv)
      ACRNAME=$(az acr list -g $SPOKERG --query [0].name -o tsv)
   ```

   Now login a second time whilst sudo'ed as root. *This is to get around a problem later where an Azure Container Registry command needs access to AZ access tokens AND the Docker Daemon at the same time - it makes installation easier if that one command runs as root.*


1. To control Kubernetes directly from the jumpbox, *kubectl* and the *kubelogin* commands must be installed.
   ```bash
   sudo snap install kubectl --classic

   sudo az aks install-cli
   ```
1. Download from Azure the configuration file for connecting to AKS.
   ```bash
   az aks get-credentials --name $AKSCLUSTERNAME --resource-group $SPOKERG
   ```
1. Test the connection by requesting a list of nodes in the cluster (you will be asked to login again so that you can obtain an AKS specific token).
   ```bash
   kubectl get nodes
   ```

### Control the default NGINX ingress controller configuration (preview)
As part of deploying our AKS environment, we enabled the [AKS app routing addon](https://learn.microsoft.com/en-us/azure/aks/app-routing). For better security, we will ensure that our applications, including the ingress controller are only available within the internal network of your orgnization. We will later expose our application to the internet using a web applicaion firewall enabled application gateway. Our first step is to ensure that our default settings for the nginx ingress controller managed by the AKS app routing addon ensures the ingress has only internal IP addresses. As of the time of writing, this is a preview feature that requires the use of aks-preview Azure CLI extension. If you do not have this installed, use the commands below to install it.

```bash
az extension add --name aks-preview
```

If you have a version of AKS-preview that is version 7.0.0b5 or later, you can just update it.

```bash
az extension update --name aks-preview
```

In addition, some preview features require you to register them. For example, to register the Deployment Safeguards feature

```bash
az feature register --namespace Microsoft.ContainerService --name SafeguardsPreview
```

Once this feature is registered, refresh the registration of the Microsoft.ContainerService provider

```bash
az provider register --namespace Microsoft.ContainerService
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

cd aks-store-demo/src

# Change directory into each app folder and build/tag the image. Example:
cd ai-service
sudo docker build . -t $ACRNAME.azurecr.io/ai-service:v1

# Do this for each app in the directory, there should be 8 in total. Remember to change the tag name for each folder:

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

> NOTE: If this fails and requires providing username and password, you might have to log into your Azure Portal and head to the ACR instance. On the left panel under settings, click on Access Keys. You will see the admin username and password there if Admin user is enabled.

## Push the images to the container registry

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
az aks update --name $AKSCLUSTERNAME  --resource-group $SPOKERG --attach-acr $ACRNAME
```

Now deploy the application using the HELM chart. Make sure to update the value of the containerRegistry in the command below to your ACR name:

```bash
cd $HOME/AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-Private-AVM/Bicep/07-Workload

helm install monkey-magic ./shoppingDemo --set containerRegistry=$ACRNAME.azurecr.io
# apply the ingress controller
kubectl apply -f shoppingDemo/templates/ingress-via-nginx-internal.yaml
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

### Testing the application internally
Your ingress controller is accessible from within the virtual network but not from the internet. Get the IP address of your ingress controller.

```bash
INGRESS_IP=$(kubectl get svc -n app-routing-system -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}')
```

Use `curl` command to test that the application is running in the cluster and the ingress was configured properly

```bash
curl $INGRESS_IP/front
```

You should see HTML code of the front end web applicatoin. If it was configured correctly, there will be no "nginx" in the HTML

### Add your new ingress as a backend pool for your application gateway so it can be accessed from the internet
First we create a backend pool name, and create the backend pool.
```bash
BACKENDPOOLNAME=aksAppRoutingPool
# change APPGW below to the correct app gateway name
az network application-gateway address-pool update \
  --resource-group $SPOKERG \
  --gateway-name APPGW \ 
  --name $BACKENDPOOLNAME \
  --servers $INGRESS_IP

```

We then run the application-gateway address-pool command to add the ingress IP address to the backend pool.
```bash
az network application-gateway address-pool update \
  --resource-group $SPOKERG \
  --gateway-name APPGW \
  --name $BACKENDPOOLNAME \
  --servers $external_ip
```

Crete HTTP Listeenr, HTTP settings and Routing rules.
```bash
az network application-gateway http-listener create \
  --resource-group $SPOKERG \
  --gateway-name APPGW \
  --name myHttpListener \
  --frontend-ip appGatewayFrontendIP \
  --frontend-port 80
```



To get the public AppGw IP address for public access:
```bash
az network public-ip show -g $SPOKERG -n APPGW-PIP --query ipAddress -o tsv

# 74.241.209.184
```
Go on your browser and try to access the application

`<ip-address>/front`

## Optional - Private DNS Zone
If you need a private DNS zone which is integrated with AKS and accessible from the jump box, the following commands will create the DNS zone, create a private link on the VNET pointing to the new zone and then update AKS.

```
az network private-dns zone create --resource-group $SPOKERG --name private.contoso.com

az network private-dns link vnet create --resource-group $SPOKERG --name privateContosoComLink --zone-name private.contoso.com --virtual-network VNet-Spoke --registration-enabled false

$ZONEID=$(az network private-dns zone show --resource-group $SPOKERG --name private.contoso.com --query "id" --output tsv)

az aks approuting zone add --resource-group $SPOKERG --name $AKSCLUSTERNAME --ids=${$ZONEID} --attach-zones
```