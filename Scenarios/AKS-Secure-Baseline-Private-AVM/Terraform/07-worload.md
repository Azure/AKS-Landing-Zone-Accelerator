# Deploy a Basic Workload using the AKS-Store-Demo Application

This application consists of a group of containerized microservices that can be easily deployed into an Azure Kubernetes Service (AKS) cluster. This is meant to show a realistic scenario using a polyglot architecture, event-driven design, and common open source back-end services (eg - RabbitMQ, MongoDB). The application also leverages OpenAI's GPT-3 models to generate product descriptions. You can find out more about the application at <https://github.com/Azure-Samples/aks-store-demo>.

As the infrastructure has been deployed in a private AKS cluster setup with private endpoints for the container registry and other components, you will need to perform the application container build and the publishing to the Container Registry from the Dev Jumpbox in the Hub VNET, connecting via the Bastion Host service.

 If your computer is connected to the hub network, you may be able to just use that as well. The rest of the steps can be performed on your local machine by using AKS Run commands which allow access into private clusters using RBAC. This will help with improving security and will provide a more user-friendly way of editing YAML files.

## Connecting to the Bastion Host

The first major step to deploying the application is to connect to the jumpbox inside the private network and authenticate to Azure and the AKS cluster.

1. From the *jumpbox* resource in the *AksTerra-AVM-LZ-RG* resource group, connect to the VM using the **Connect via Bastion**.

1. If prompted, allow the browser to read the contents of your clipboard.

1. From the jumpbox command line, clone the *aks-landing-Zone-Accelerator* repository which contains some setup scripts needed shortly.

   ```bash
   git clone https://github.com/Azure/AKS-Landing-Zone-Accelerator/
   ```

1. Run the setup script to apply the latest updates to the jumpbox and to install other required packages.

   ```bash
   cd AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/07-Workload

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

As part of deploying our AKS environment, we enabled the [AKS app routing addon](https://learn.microsoft.com/en-us/azure/aks/app-routing). For better security, we will ensure that our applications, including the ingress controller are only available within the internal network of your organization. We will later expose our application to the internet using a web application firewall enabled application gateway. Our first step is to ensure that our default settings for the nginx ingress controller managed by the AKS app routing addon ensures the ingress has only internal IP addresses. As of the time of writing, this is a preview feature that requires the use of aks-preview Azure CLI extension. If you do not have this installed, use the commands below to install it.

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

Now that you have enabled the preview feature, run the command below to update the default configuration of your app routing addon so that by default, it deploys ingress controllers with internal ip addresses.

```bash
az aks approuting update --resource-group $SPOKERG --name $AKSCLUSTERNAME --nginx Internal
```

## Build Container Images

Clone the sample application Git Repo to the Dev Jumpbox:

1. The AKS Store Demo repo:

```bash
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

Ensure your ACR now has all the images you need by running the command below

```bash
az acr repository list --name $ACRNAME --output table

# Result
# ----------------
# ai-service
# makeline-service
# mongo
# order-service
# product-service
# rabbitmq
# store-admin
# store-front
# virtual-customer
# virtual-worker
```

You should also connect your AKS Cluster to the Azure Container Registry (ACR) so when it attempts to pull images it can authenticate correctly:

```bash
az aks update --name $AKSCLUSTERNAME  --resource-group $SPOKERG --attach-acr $ACRNAME
```

Now deploy the application using the HELM chart. Make sure to update the value of the containerRegistry in the command below to your ACR name:

```bash
cd $HOME/AKS-Landing-Zone-Accelerator/Scenarios/AKS-Secure-Baseline-PrivateCluster/Bicep/07-Workload

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

```bash
kubectl get ingress
```

```bash
NAME               CLASS                                HOSTS   ADDRESS     PORTS   AGE
internal-ingress   webapprouting.kubernetes.azure.com private.contoso.com       10.1.1.10   80      14s
```

### Testing the application internally

Your ingress controller is accessible from within the virtual network but not from the internet. Private DNS Zone has been configured with hostname private.contoso.com.

Use `curl` command to test that the application is running in the cluster and the ingress was configured properly

```bash
curl http://private.contoso.com
```

```bash
<!doctype html><html lang=""><head><meta charset="utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="/favicon.ico"><title>store-front</title><script defer="defer" src="/js/chunk-vendors.1541257f.js"></script><script defer="defer" src="/js/app.1a424918.js"></script><link href="/css/app.0f9f08e7.css" rel="stylesheet"></head><body><noscript><strong>We're sorry but store-front doesn't work properly without JavaScript enabled. Please enable it to continue.
```

The ingress controller is also able to reach the store-admin service

```bash
curl http://private.contoso.com/admin
```

```bash
<!doctype html><html lang=""><head><meta charset="utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="viewport" content="width=device-width,initial-scale=1"><link rel="icon" href="/favicon.ico"><title>store-admin</title><script defer="defer" src="/js/chunk-vendors.ee0766ad.js"></script><script defer="defer" src="/js/app.3a737ea9.js"></script><link href="/css/app.3505fa4f.css" rel="stylesheet"></head><body><noscript><strong>We're sorry but store-admin doesn't work properly without JavaScript enabled. Please enable it to continue.</strong></noscript><div id="app"></div></body></html>
```

You should see HTML code of the front end web application. If it was configured correctly, there will be no "nginx" in the HTML

As part of our Terraform deployment code, we already created a backend pool, routing rule, HTTP rules, a PUBLIC frontend IP configuration and a HTTP Listener for the App gateway. This will allow us to expose our app externally with our App gateway. Run the application-gateway address-pool command to add the ingress IP address to the backend pool.

To get the public AppGw IP address for public access:

```bash
az network public-ip show -g $SPOKERG -n pip-appgw --query ipAddress -o tsv

# 74.241.209.184
```

Go on your browser and enter the IP address to access your application.
