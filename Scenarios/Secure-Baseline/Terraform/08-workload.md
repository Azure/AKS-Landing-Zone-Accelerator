# Deploy a Basic Workload using the Fruit Smoothie Ratings Application

This application is provided by Microsoft Learning and is used as part of a self-paced Kubernetes training workshop.  You may find reviewing that workshop helpful as it presents some alternative deployment options and features using different architecture requirements. The application consists of a web frontend, an API service and a MongoDB database.

Because the infrastructure has been deployed in a secure manner, only the API server to the AKS Cluster is accessible outside of the private network.  You will need to perform the majority of the application deployment from the Dev Jumpbox in the Hub VNET, connect via the Bastion Host service.

Install the following applications:
1. git
2. AZ CLI
3. Docker
4. Kubernetes CLI
5. Helm

Once connected, install the Azure CLI and log into Azure. You must be a member of the appropriate
group (AKS App Dev Users, AKS Operations) to access the cluster. 

```
az login
```

If you need to log in with a serice account:
```
az login --service-principal --username "${applicationId}" --password "${password}" --tenant "${tenantID}"
```

Get the connection credentials for the cluster:
```
az aks get-credentials --name MyManagedCluster --resource-group MyResourceGroup
```

Install the kubectl CLI:
```
az aks install-cli
```

Clone the required repos to the Dev Jumpbox:
1. This repo
```
git clone
```
2. The Ratings API repo
```
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git
```
3. The Ratingss Web repo
```
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git
```

Navigate to each of the application code directories, build and tag the containers with the name of your Azure Container Registry and push the images to ACR.
```
docker build . -t <acrname>.azurecr.io/ratings-api:v1
docker build . -t <acrname>.azurecr.io/ratings-web:v1

docker push <acrname>.azurecr.io/ratings-api:v1
docker push <acrname>.azurecr.io/ratings-web:v1
```

On the Kubernetes cluster, create a namespace for the Ratings Application. 
```
kubectl create namespace ratingsapp
```

The MongoDB backend application is installed using Helm. You may use anything you'd like for the username and password for the MongoDB database, however that needs to be reflected in the connection string that is placed in Key Vault.  
```
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=dbadmin,auth.password=Passw0rd1,auth.database=ratingsdb
```

Navigate to "/Scenarios/Secure-Baseline/Apps/RatingsApp" folder. 
```
cd //Scenarios/Secure-Baseline/Apps/RatingsApp
```
Update the "0-secret-provider-class.yaml" file to reflect the correct Key Vault name, Client ID for the AKS Key Vault Add-on and the Tenant ID for the subscription.  Deploy the edited yaml file.

Update the "1-ratings-api-deployment.yaml" file to reflect the correct name for the Azure Container Service.  Deploy the file.

Deploy the "2-ratings-api-service.yaml" file.

Update the "3-ratings-web-deployment.yaml" file to reflect the correct name for the Azure Container Service. Deploy the file. 

Deploy the "4-ratings-web-serivce.yaml" file.

Deploy the "5-ratings-web-ingress.yaml" file.

Browse to the IP address of the external IP for the Application Gateway.


