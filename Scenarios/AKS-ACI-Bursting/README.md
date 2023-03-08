
# Bursting from AKS to ACI
This example scenario showcases how to rapidly scale up the workload instances in Azure Kubernetes Services using the serverless compute capacity provided by Azure Container Instances.

AKS Virtual Nodes allows AKS users to make use of the compute capacity of Azure Container Instances (ACI) to spin up additional containers rather than having to bring up additional VM based worker nodes in the cluster. AKS Virtual Nodes helps leverage Azure's serverless container hosting services to extend Kubernetes service using the Virtual Kubelet implementation. This integration requires the AKS cluster to be created with advanced networking - Azure Container Networking Interface (Azure CNI).

This deployable solution contains two parts:
* Deploying the infrastructure required for virtual nodes. 
* Deploying the scalable application components to the AKS cluster and testing the scaling to virtual nodes 

In order to deploy this scenario, you will need the following:

- An active [Microsoft Azure](https://azure.microsoft.com/en-us/free "Microsoft Azure") Subscription
- Azure Cloud Shell or bash cli with the following installed:
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/overview?view=azure-cli-latest "Azure CLI") installed
  - [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/tasks/tools/install-kubectl/ "Kubernetes CLI (kubectl)") installed
  - Azure Bicep installed (optional)



**NOTE**: This scenario will be focusing on showcasing the capability of using virtual nodes with AKS, and for that purpose some of the advanced security configurations like private cluster, Azure policies, ingress controllers, etc. are skipped here. Please refer to the [AKS Accelerator scenarios](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios) for advanced, and secure configurations.


# Infrastructure Deployment
## Create AKS Cluster with Virtual Nodes

Create a new AKS cluster with virtual nodes enabled or enable virtual nodes on an existing AKS cluster by following one of the options below.

### Option1 : Create a new AKS cluster with Virtual Nodes enabled

```bash
# Change the values for the parameters as needed for your own environment
az group create --name aksdemorg --location eastus
az deployment group create \
  --name aksinfra-demo \
  --resource-group aksdemorg \
  --template-file ./deployment/aksinfra.bicep \
  --parameters aksname='aksdemo'
  --parameters acrname='aksacr0022'
  --parameters vnetname='demo-vnet'
  --parameters location='eastus'
```
Executing the above bicep template will create the following new resources/configurations.
* 1 VNET with 2 subnets 
* 1 AKS cluster with virtual nodes enabled
* 1 Container registry
* Required RBAC assignments on the VNET and the ACR



### Option2 : Enable Virtual Nodes on an existing AKS cluster
Existing AKS clusters can be updated to enable virtual nodes. Please make sure that Advanced CNI networking is configured for the cluster and there is a new dedicated empty subnet created in the same vnet. 

```bash
# Enable virtual nodes on a existing AKS cluster
# Change the values as needed for your own environment
az aks enable-addons \
    -g <resource-group> \
    --name <AKS_Cluster> \
    --addons virtual-node \
    --subnet-name <aciSubnet>
```

## Create the Storage Account and fileshare
In this scenario, we will use an Azure File share as a shared persistent storage consumed by multiple replicas of the application pods.

To create the fileshare, run the following az commands 

```bash
# Change the values for these four parameters as needed for your own environment
AKS_PERS_STORAGE_ACCOUNT_NAME=acidemostorage$RANDOM
AKS_PERS_RESOURCE_GROUP=aksdemorg
AKS_PERS_LOCATION=eastus
AKS_PERS_SHARE_NAME=aksshare

# Create a storage account
az storage account create -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -l $AKS_PERS_LOCATION --sku Standard_LRS

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=$(az storage account show-connection-string -n $AKS_PERS_STORAGE_ACCOUNT_NAME -g $AKS_PERS_RESOURCE_GROUP -o tsv)

# Create the file share
az storage share create -n $AKS_PERS_SHARE_NAME --connection-string $AZURE_STORAGE_CONNECTION_STRING

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $AKS_PERS_RESOURCE_GROUP --account-name $AKS_PERS_STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)

# Echo storage account name and key
echo Storage account name: $AKS_PERS_STORAGE_ACCOUNT_NAME | base64
echo Storage account key: $STORAGE_KEY
```

# Application deployment and Testing
## Validate the cluster
Before start deploying the applications, make sure that the virtual nodes are up and running fine within the AKS cluster. 
Run the following commands to connect to the cluster and list the cluster nodes
```bash
az aks get-credentials --resource-group aksdemorg --name aksdemo
kubectl get nodes
```
Output will look like below:
```bash 
NAME                                STATUS   ROLES   AGE   VERSION
aks-agentpool-74340005-vmss000000   Ready    agent   13m   v1.24.6
virtual-node-aci-linux              Ready    agent   11m   v1.19.10-vk-azure-aci-1.4.8
```
The node "virtual-node-aci-linux" in the above output indicates that the virtual nodes are configured and running fine within the AKS cluster.

## Push container image to Azure Container Registry
Before deploying the application to the AKS cluster, we need to have it built and uploaded to the Azure Container registry. To keep this excercise simple, we will import a publicly available image to ACR using 'az acr import' command, which will be used as our demo app. Alternatively, you can build your custom application images and push them to ACR using docker commands or CI/CD pipelines.

```bash
  az acr import \
  --name <ACR_NAME> \
  --source docker.io/library/nginx:latest \
  --image aci-aks-demo:latest
```
## Configuring secrets
The application pods use Azure Fileshare as the persistent storage, for which a kubernetes secret referencing the storage account and the access key needs to be created. 

Use the exported values from the previous section and run the following command:
```bash
kubectl create secret generic azure-secret \
--from-literal=azurestorageaccountname=$AKS_PERS_STORAGE_ACCOUNT_NAME \
--from-literal=azurestorageaccountkey=$STORAGE_KEY
```
Similarly for pulling the images from container registry, a secret should be created referencing the service principal credentials which has acrpull access on the registry. 

```bash
#!/bin/bash
# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
ACR_NAME=aksacr009
SERVICE_PRINCIPAL_NAME=demo-aks-acr-pullsecret

# Obtain the full registry ID
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query "id" --output tsv)

# Create the service principal with rights scoped to the registry.
PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)

# Output the service principal's credentials; use these in your services and applications to authenticate to the container registry.
echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"
```

Now create a kubernetes secret with the above credentials to access the container regitry
```bash
kubectl create secret docker-registry acr-pull-secret \
    --namespace default \
    --docker-server=$ACR_NAME.azurecr.io \
    --docker-username=$USER_NAME \
    --docker-password=$PASSWORD
```

## Deploy the application

By now, we have setup the cluster with virtual nodes and created all the necessary secrets in the cluster. Next step is the sample application deployment. 

Deploy the sample application to the AKS cluster using the following command. Make sure that you have updated the image reference under container specs in the yaml file to point to your Azure Container registry url. 

```bash 
#Please make sure to modify the <ACR_NAME> in the yaml file before applying it. 

kubectl apply -f deployment/demoapp-deploy.yaml
```
The above command deploys 1 replica of the application and creates a service to expose it on port 80. The application pod will have the Azure Fileshare mounted to the /mnt/azure directory. 

Validate the deployment and service by running the following commands:
```bash 
kubectl get deploy demoapp-deploy

NAME             READY   UP-TO-DATE   AVAILABLE   AGE
demoapp-deploy   1/1     1            1           14s
```
```bash
kubectl get svc demoapp-svc

NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
demoapp-svc   ClusterIP   10.0.50.82   <none>        80/TCP    114s
```

## Configure auto-scaling for the application
We now have the sample application as part of the deployment, and the service is accessible on port 80. To scale the resources, we will use a Horizontal Pod Autoscaler based on CPU usage to scale up the replicas of the pod, when traffic increases and scale down the resources when traffic decreases.

```bash
kubectl apply -f deployment/demoapp-hpa.yaml
```
Verify the HPA deployment:

```bash
kubectl get hpa
```
The above output shows that the HPA maintains between 1 and 10 replicas of the pods controlled by the reference deployment and a  target of 50% is the average CPU utilization that the HPA needs to maintain, whereas the target of 0% is the current usage.

## Load Testing
To test HPA in real-time, let’s increase the load on the cluster and check how HPA responds in managing the resources.

First, let’s check the current status of the deployment:
```bash
kubectl get deploy
```
For simulating user load, we will start a few containers in a different namespace and send an infinite loop of queries to the demo-app service, listening on port 80. This will make the CPU consumption in the target containers high. 

Open a new bash terminal and execute the below command:

```bash
kubectl create ns loadtest
kubectl apply -f deployment/load_deploy.yaml -n loadtest
```
Once you triggered the load test, use the below command to check the status of the HPA in real time:

```bash
kubectl get hpa -w

NAME          REFERENCE                   TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
demoapp-hpa   Deployment/demoapp-deploy   44%/50%   1         10        1          29m
demoapp-hpa   Deployment/demoapp-deploy   56%/50%   1         10        2          29m
demoapp-hpa   Deployment/demoapp-deploy   100%/50%   1         10        2          30m
```
You can now see that as the usage went up, the number of pods started scaling up.


You should be able to see that the additional pods started getting deployed in the virtual nodes.

```bash
$ kubectl get pods -o wide

NAME                              READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
demoapp-deploy-7544f8b99d-g5kwj   1/1     Running   0          2m21s   10.100.0.26   virtual-node-aci-linux              <none>           <none>
demoapp-deploy-7544f8b99d-k4w99   1/1     Running   0          13m     10.100.1.28   aks-agentpool-74340005-vmss000000   <none>           <none>
demoapp-deploy-7544f8b99d-sqkv8   1/1     Running   0          2m21s   10.100.0.29   virtual-node-aci-linux              <none>           <none>
```

Create a file with some dummy data in the mounted file share

```bash
kubectl exec -it demoapp-deploy-b9fbcbfcb-57fq8 -- /bin/sh 
# echo "hostname" > /mnt/azure/`hostname`
# ls /mnt/azure/
demoapp-deploy-b9fbcbfcb-57fq8
```

Validate the newly created file from one of the replicas running in the aks vm nodepools. 

```bash
kubectl exec -it demoapp-deploy-85889899bc-rm6j5 sh 
# ls /mnt/azure/
demoapp-deploy-b9fbcbfcb-57fq8
```
You can also view the files in the Azure Fileshare:
![image](https://user-images.githubusercontent.com/40350122/216344051-8f0ca0ec-ba6f-43ba-b1c5-63f9d4887d59.png)


### Stop the load

Stop the load by deleting the *loadtest* namespace:

```bash
kubectl delete ns loadtest
```
Once the load is stopped, you will see that the pod replicas will come down.

```bash
kubectl get pods -o wide
NAME                             READY   STATUS        RESTARTS       AGE   IP             NODE                                NOMINATED NODE   READINESS GATES
demoapp-deploy-b9fbcbfcb-57fq8   1/1     Running       0              21m   10.100.1.85    aks-agentpool-74340005-vmss000000   <none>           <none>
```
